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
    
    private var lastRequests: [RequestInfo]? = nil
    
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
        await self.setupModules(modules)

        await withTaskGroup(of: Void.self) { tasks in
            for (rnumber, url) in phishURLS.enumerated() {
                tasks.addTask { [self] in
                    var info = RequestInfo(url: url)
                    info.requestID = rnumber
                    info.failedOnModulesCount = 3
                    for item in modules {
                        var mod = item.getModule()
                        mod.dependences.append(contentsOf: self.globalDependences)
                        info.addModule(mod)
                    }
                    await info.executeAll(
                        onRequestFinished: { r in
                            onQueue.async {
                                onRequestFinished?(r)
                            }
                        },
                        onModuleFinished: { r, m in
                            onQueue.async {
                                onModuleFinished?(r,m)
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
                        onRequestFinished: { r in
                            onQueue.async {
                                onRequestFinished?(r)
                            }
                        },
                        onModuleFinished: { r, m in
                            onQueue.async {
                                onModuleFinished?(r, m)
                            }
                        })
                }
            }
        }
        
        
        return lastRequests
    }
}
