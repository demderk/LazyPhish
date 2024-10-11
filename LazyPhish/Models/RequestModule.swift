//
//  RequestModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

protocol RequestModule: AnyObject {
    var dependences: DependencyCollection { get set }
    var status: ModuleStatus { get }

    func execute(remote: RequestInfo) async
    func execute(remote: RequestInfo, onFinish: (RequestInfo, RequestModule) -> Void) async
    func processDependences(remote: RequestInfo, parentDependences: DependencyCollection) async -> DependencyCollection
}

extension RequestModule {
    func execute(remote: RequestInfo, onFinish: (RequestInfo, RequestModule) -> Void) async {
        await execute(remote: remote)
        onFinish(remote, self)
    }
    
    func processDependences(remote: RequestInfo, parentDependences: DependencyCollection) async -> DependencyCollection {
        var internalDependences: DependencyCollection = parentDependences
        for dependency in await dependences.collection {
            if dependency.completed {
                continue
            }
            if let executed = await parentDependences.getDependency(module: dependency),
               executed.completed {
                await dependences.putDependency(
                    oldModule: dependency,
                    newModule: executed)
            }
            else {
                await internalDependences.pushUniqueDependencies(dependency.processDependences(remote: remote, parentDependences: internalDependences))
                await dependency.execute(remote: remote)
                await internalDependences.pushDependency(dependency)
            }
        }
        return internalDependences
    }
    
    /// Returns true if module status is completed
    var completed: Bool {
        if case .completed = status {
            return true
        } else { return false }
    }
    
    /// Returns true if module status is completed or completed with errors
    var finished: Bool {
        switch status {
        case .completed: return true
        case .completedWithErrors(_): return true
        default: return false
        }
    }
}
