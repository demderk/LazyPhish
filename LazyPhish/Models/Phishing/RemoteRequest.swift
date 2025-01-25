//
//  RemoteInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation

enum RemoteRequestError: RemoteJobError {
    case anyModulesFailed(collection: [ModuleError])
    case injectionModuleExecutionFailed
}

enum UnknownModuleError: ModuleError {
    case unknown(_ underlyingError: Error?)
}

// TODO: [DOCS REQUIRED]
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
    
    // А написать почему оно депрекейтед?
//    @available(*, deprecated)
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
    
    /// Executes all modules and dependencies.
    ///
    /// Modules that are not passed through the dependency injection mechanism will not be passed further down the pipeline.
    /// Since each module is executed in a separate thread, there is no guarantee that they will execute sequentially.
    /// Therefore, it is not possible to explicitly pass the previous module to the next one.
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
                    return error as? ModuleError ?? UnknownModuleError.unknown(error)
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
        
        if moduleErrors.count > 0 {
            return .failed(RemoteRequestError.anyModulesFailed(collection: moduleErrors))
        } else if moduleWarinigs.count > 0 {
            return .completedWithErrors(moduleWarinigs)
        } else {
            return .completed
        }
    }
    
    /// Adds the provided module as a dependency without executing it. The dependency is directly injected into all related modules.
    ///
    /// Be careful: the dependency will be executed automatically, but if the dependency fails, it will be passed through the pipeline as failed without any warning.
    func forcePushDependency(_ module: any RequestModule) async {
        await dependencyModules.pushDependency(module)
    }
    
    /// Performs dependency injection. Executes the provided module, and if the module completes successfully,
    /// injects the dependency into all related modules. If the execution fails, an error is returned.
    func injectDependency(_ module: any RequestModule) async throws {
        await module.execute(remote: self)
        guard module.status.isFinished else {
            throw RemoteRequestError.injectionModuleExecutionFailed
        }
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
