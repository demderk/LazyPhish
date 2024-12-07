//
//  PhishRequestQuerry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation

class PhishRequestQueue {
    var phishURLS: [StrictURL] = []
    var globalDependences: [RequestModule] = []

    private var lastRequests: [RemoteRequest]?

    func setupModules(_ modules: [DetectTool]) async {
        for module in modules {
            switch module {
            case .opr:
                if !globalDependences.contains(where: { $0 is BulkOPRModule }) {
                    let bulkModule = BulkOPRModule()
                    await bulkModule.bulk(phishURLS)
                    globalDependences.append(bulkModule)
                }
                fallthrough
            default:
                break
            }
        }
    }

    @discardableResult
    func executeAll(modules: [DetectTool],
                    onModuleFinished: ((RemoteRequest, RequestModule) -> Void)? = nil,
                    onRequestFinished: ((RemoteRequest) -> Void)? = nil,
                    onQueue: DispatchQueue = DispatchQueue.main
    ) async -> [RemoteRequest] {
        var result: [RemoteRequest] = []
        let oprBulk = BulkOPRModule()
        await oprBulk.bulk(phishURLS)
        
        await withTaskGroup(of: Void.self) { tasks in
            
            let resultMutex = Mutex()
            
            for (rnumber, url) in phishURLS.enumerated() {
                tasks.addTask {
                    let info = RemoteRequest(url: url)
                    info.requestID = rnumber
                    info.failedOnModulesCount = 3
                    for item in modules {
                        info.addModule(item.getModule())
                    }
                    await info.addBroadcastModule(oprBulk)
                    await info.executeAll(
                        onRequestFinished: { request in
                            onQueue.async {
                                onRequestFinished?(request)
                            }
                        },
                        onModuleFinished: { request, module in
                            onQueue.async {
                                onModuleFinished?(request, module)
                            }
                        })
                    await resultMutex.withLock {
                        result.append(info)
                    }
                }
            }
        }
        lastRequests = result
        return result
    }

    @discardableResult
    func reviseLastRequest(
        onModuleFinished: ((RemoteRequest, RequestModule) -> Void)? = nil,
        onRequestFinished: ((RemoteRequest) -> Void)? = nil,
        onQueue: DispatchQueue = DispatchQueue.main
    ) async -> [RemoteRequest]? {
        guard let requests = lastRequests else {
            return nil
        }
        await withTaskGroup(of: Void.self) { tasks in
            for request in requests {
                tasks.addTask {
                    await request.revise(
                        onRequestFinished: { request in
                            onQueue.async {
                                onRequestFinished?(request)
                            }
                        },
                        onModuleFinished: { request, module in
                            onQueue.async {
                                onModuleFinished?(request, module)
                            }
                        })
                }
            }
        }

        return lastRequests
    }
}
