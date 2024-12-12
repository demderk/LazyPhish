//
//  RemoteInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation

enum RemoteRequestError: RemoteJobError {
    case anyModulesFailed(collection: [ModuleError])
}

class RemoteRequest: Identifiable {
    // TODO: Make private(set)
    var id: Int? { self.requestID }
    
    private(set) var modules: [any RequestModule] = []
    
    private var dependencyModules: DependencyCollection = DependencyCollection()
    
    var requestID: Int?
    var url: StrictURL
    var status: RemoteJobStatus = .planned
    var failedOnModulesCount: Int?
    
    var host: String { url.strictHost }
    var hostRoot: String { url.hostRoot }
    
    init(url: StrictURL) {
        self.url = url
    }
    
    @available(*, deprecated)
    func executeAll(
        onRequestFinished: ((RemoteRequest) -> Void)? = nil,
        onModuleFinished: ((RemoteRequest, RequestModule) -> Void)? = nil
    ) async {
        status = .executing
        status = await executeModules(onModuleFinished: onModuleFinished)
        onRequestFinished?(self)
    }
    
    func revise(
        onRequestFinished: ((RemoteRequest) -> Void)? = nil,
        onModuleFinished: ((RemoteRequest, RequestModule) -> Void)? = nil
    ) async {
        if case .failed = status {
            await executeAll(
                onRequestFinished: onRequestFinished,
                onModuleFinished: onModuleFinished)
            return
        } else if case .completedWithErrors = status {
            status = .executing
            status = await executeModules(onModuleFinished: onModuleFinished, skipCompleted: true)
            onRequestFinished?(self)
        }
    }
    
    private func executeModules (
        onModuleFinished: ((RemoteRequest, RequestModule) -> Void)?,
        skipCompleted: Bool = false
    ) async -> RemoteJobStatus {
        
        // Processing dependences first
        
        await withTaskGroup(of: Void.self) { tasks in
            for mod in modules {
                tasks.addTask {
                    await mod.processDependences(remote: self, parentDependences: self.dependencyModules)
                }
            }
        }
        
        let arrayMutex = Mutex()
        
        // Continue execution with finished dependences
        
        await withTaskGroup(of: Void.self) { tasks in
            // TODO: rewrite modules array to ModulesCollection Actor
            
            for (n, mod) in modules.enumerated() {
                if skipCompleted, case .completed = mod.status {
                    continue
                }
                if let executed = await dependencyModules.getDependency(module: mod),
                   case .completed = executed.status {
                    await arrayMutex.withLock { [self] in
                        modules[n] = executed
                    }
                } else {
                    tasks.addTask { [self] in
                        await mod.execute(remote: self, onFinish: onModuleFinished)
                        await dependencyModules.pushDependency(mod)
                    }
                }
            }
        }
        
        let moduleErrors = modules
            .compactMap({
                if case .failed(let error) = $0.status {
                    return error as? ModuleError
                }
                return nil
            })
        
        let moduleWarinigs = modules
            .flatMap({
                if case .completedWithErrors(let error) = $0.status {
                    return error ?? []
                }
                return []
            })
        
        let failedOn = failedOnModulesCount ?? modules.count
        if moduleErrors.count > 0 {
            return .failed(RemoteRequestError.anyModulesFailed(collection: moduleErrors))
        } else if moduleWarinigs.count > 0 {
            return .completedWithErrors(moduleWarinigs)
        } else {
            return .completed
        }
    }
    
    func addBroadcastModule(_ module: any RequestModule) async {
        //        await module.execute(remote: self)
        await dependencyModules.pushDependency(module)
    }
    
    func addModule(_ module: any RequestModule) {
        modules.append(module)
    }
    
    func addModule(contentsOf: [any RequestModule]) {
        modules.append(contentsOf: contentsOf)
    }
    
    func getModule<T: RequestModule>(module: T.Type) -> RequestModule? {
        return modules.first(where: { type(of: $0) == module })
    }
    
    func getCompletedModule<T: RequestModule>(module: T.Type) -> T? {
        return modules.first(where: { type(of: $0) == module && $0.completed }) as? T
    }
    
    func getFinishedModule<T: RequestModule>(module: T.Type) -> T? {
        return modules.first(where: { type(of: $0) == module && $0.finished }) as? T
    }
}
