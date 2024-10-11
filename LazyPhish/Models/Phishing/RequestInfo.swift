//
//  RemoteInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation

class RequestInfo {
    // TODO: Make private(set)
    
    private(set) var modules: [any RequestModule] = []
    
    private var dependencyModules: DependencyCollection = DependencyCollection()
    
    var requestID: Int?
    var url: StrictURL
    var status: RemoteStatus = .planned
    var failedOnModulesCount: Int?
    
    init(url: StrictURL) {
        self.url = url
    }
    
    func executeAll(
        onRequestFinished: ((RequestInfo) -> Void)? = nil,
        onModuleFinished: ((RequestInfo, RequestModule) -> Void)? = nil
    ) async {
        status = .executing
        status = await executeModules(onModuleFinished: onModuleFinished)
        onRequestFinished?(self)
    }
    
    func revise(
        onRequestFinished: ((RequestInfo) -> Void)? = nil,
        onModuleFinished: ((RequestInfo, RequestModule) -> Void)? = nil
    ) async {
        if case .failed = status {
            await executeAll(
                onRequestFinished: onRequestFinished,
                onModuleFinished: onModuleFinished)
            return
        } else if case .completedWithErrors = status  {
            status = .executing
            status = await executeModules(onModuleFinished: onModuleFinished, skipCompleted: true)
            onRequestFinished?(self)
        }
    }
    
    private func executeModules (
        onModuleFinished: ((RequestInfo, RequestModule) -> Void)?,
        skipCompleted: Bool = false
    ) async -> RemoteStatus {
        await withTaskGroup(of: Void.self) { tasks in
            for mod in modules {
                tasks.addTask {
                    await mod.processDependences(remote: self, parentDependences: self.dependencyModules)
                }
            }
        }
        
        await withTaskGroup(of: Void.self) { tasks in
            for (n, mod) in modules.enumerated() {
                if skipCompleted, case .completed = mod.status {
                    continue
                }
                if let executed = await dependencyModules.getDependency(module: mod),
                   case .completed = executed.status {
                    modules[n] = executed
                } else {
                    _ = tasks.addTaskUnlessCancelled { [self] in
                        if let finished = onModuleFinished {
                            await mod.execute(remote: self, onFinish: finished)
                        } else {
                            await mod.execute(remote: self)
                        }
                        await dependencyModules.pushDependency(mod)
                    }
                }
            }
        }
        let failedModules = modules.count(where: {
            if case ModuleStatus.failed(_) = $0.status {
                return true
            }
            return false
        })
        
        let failedOn = failedOnModulesCount ?? modules.count
        if failedModules >= failedOn {
            return .failed
        }
        else if failedModules > 0 {
            return .completedWithErrors
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
