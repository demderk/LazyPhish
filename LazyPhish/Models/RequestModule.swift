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
    var status: RemoteJobStatus { get }

    func execute(remote: RemoteRequest) async
    func execute(remote: RemoteRequest, onFinish: ((RemoteRequest, RequestModule) -> Void)?) async
    
    @discardableResult
    func processDependences(
        remote: RemoteRequest,
        parentDependences: DependencyCollection
    ) async -> DependencyCollection
}

extension RequestModule {
    func execute(remote: RemoteRequest, onFinish: ((RemoteRequest, RequestModule) -> Void)?) async {
        await execute(remote: remote)
        onFinish?(remote, self)
    }
    
    @discardableResult
    func processDependences(
        remote: RemoteRequest,
        parentDependences: DependencyCollection
    ) async -> DependencyCollection {
        let internalDependences: DependencyCollection = parentDependences
        for dependency in await dependences.collection {
            if dependency.completed {
                continue
            }
            if let executed = await parentDependences.getDependency(module: dependency),
               executed.completed {
                await dependences.putDependency(
                    oldModule: dependency,
                    newModule: executed)
            } else {
                await internalDependences.pushUniqueDependencies(
                    dependency.processDependences(
                        remote: remote,
                        parentDependences: internalDependences))
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

    var failed: Bool {
        if case .failed = status {
            return true
        } else { return false }
    }
    
    /// Returns true if module status is completed or completed with errors
    var finished: Bool {
        switch status {
        case .completed: return true
        case .completedWithErrors: return true
        default: return false
        }
    }
}
