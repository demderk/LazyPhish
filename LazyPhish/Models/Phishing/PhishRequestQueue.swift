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

    private var lastRequests: [RequestInfo]?

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
                    onModuleFinished: ((RequestInfo, RequestModule) -> Void)? = nil,
                    onRequestFinished: ((RequestInfo) -> Void)? = nil,
                    onQueue: DispatchQueue = DispatchQueue.main
    ) async -> [RequestInfo] {
        var result: [RequestInfo] = []
        let oprBulk = BulkOPRModule()
        await oprBulk.bulk(phishURLS)

        await withTaskGroup(of: Void.self) { tasks in
            for (rnumber, url) in phishURLS.enumerated() {
                tasks.addTask {
                    let info = RequestInfo(url: url)
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
                    result.append(info)
                }
            }
        }
        lastRequests = result
        return result
    }

    @discardableResult
    func reviseLastRequest(
        onModuleFinished: ((RequestInfo, RequestModule) -> Void)? = nil,
        onRequestFinished: ((RequestInfo) -> Void)? = nil,
        onQueue: DispatchQueue = DispatchQueue.main
    ) async -> [RequestInfo]? {
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
