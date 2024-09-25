//
//  PhishRequestQuerry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation

class NeoPhishRequestQueue {
    var phishURLS: [StrictURL] = []
    var globalDependences: [RequestModule] = []
    
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
    
    func executeAll(modules: [DetectTool]) async -> [RemoteInfo] {
        var result: [RemoteInfo] = []
        await self.setupModules(modules)
        
        await withTaskGroup(of: Void.self) { tasks in
            for url in phishURLS {
                tasks.addTask {
                    var info = RemoteInfo(url: url)
                    for item in modules {
                        var mod = item.getModule()
                        mod.dependences.append(contentsOf: self.globalDependences)
                        info.addModule(mod)
                    }
                    await info.executeAll()
                    result.append(info)
                }
            }
        }
        
        return result
    }
}

class PhishRequestQueue: PhishRequest {
    private var isCanceled: Bool = false
    private(set) var phishInfo: [PhishInfo] = []
    private var mainSemaphore = Semaphore(count: 100)
    
    // MARK: INITS
    
    init(_ urlStrings: [String] ) throws {
        phishInfo.append(contentsOf: try urlStrings.map({ try PhishInfo($0) }))
    }
    
    init(_ urlStrings: [Int: String], preActions: Set<FormatPreaction> ) throws {
        phishInfo.append(contentsOf: try urlStrings.map({ key, value in
            var item = try PhishInfo(value, preActions: preActions)
            item.requestID = key
            return item
        }))
    }
    
    init(_ urlStrings: [String], preActions: Set<FormatPreaction> ) throws {
        phishInfo.append(contentsOf: try urlStrings.map({ try PhishInfo($0, preActions: preActions) }))
    }
    
    init(urls: [URL]) throws {
        phishInfo.append(contentsOf: try urls.map({ try PhishInfo(url: $0) }))
    }
    
    override init() {
        super.init()
    }
    
    convenience init(_ urlStrings: String...) throws {
        try self.init(urlStrings)
    }
    
    public func phishInfo(_ urlStrings: [String]) throws {
        phishInfo.append(contentsOf: try urlStrings.map({ try PhishInfo($0) }))
    }
    
    // MARK: Main logic
   
    public func refreshRemoteData(
        onRequestComplete: ((PhishInfo) -> Void)?,
        onTaskComplete: @escaping (([PhishInfo]) -> Void),
        onQueue: DispatchQueue = DispatchQueue.main
    ) {
        let neo = RemoteInfo(url: try! .init(url: "http://googlek.com"))
        var bulk = BulkOPRModule()
//        neo.modules.append(OPRModule(bulk: bulk))
        Task {
            await bulk.bulk([try! .init(url: "http://google.com"),
                             try! .init(url: "http://vk.com"),
                             try! .init(url: "http://youtube.com")])
            await neo.executeAll()
        }
        onTaskComplete(self.phishInfo)
//        Task {
//            phishInfo = await refreshRemoteData(
//                phishInfo,
//                collectMetrics: [YandexSQIPipeline(),
////                                 OPRPipeline(),
//                                 WhoisPipeline()],
//                requestCompleted: onRequestComplete)
//            onQueue.async {
//                onTaskComplete(self.phishInfo)
//            }
//        }
    }

    override func refreshRemoteData(
        _ base: any StrictRemote,
        collectMetrics: [PhishingPipelineObject]
    ) async -> PhishInfo {
        await mainSemaphore.wait()
        let x = await super.refreshRemoteData(base, collectMetrics: collectMetrics)
        await mainSemaphore.signal()
        return x
    }
    
    public func cancel() {
        isCanceled = true
    }
    
    private func refreshRemoteData(
        _ base: [StrictRemote],
        collectMetrics: [PhishingPipelineObject],
        requestCompleted: ((PhishInfo) -> Void)? = nil,
        onQueue: DispatchQueue = DispatchQueue.main
    ) async -> [PhishInfo] {
        var remote = base
        var metrics: [PhishingPipelineObject] = []
        
        for metric in collectMetrics {
            if let pipe = metric as? PhishingArrayPipelineObject {
                remote = await pipe.executeAll(data: base)
            } else {
                metrics.append(metric)
            }
        }
        let finalMetrics = metrics
        
        return await withTaskGroup(of: PhishInfo.self) { taskGroup in
            for item in remote {
                taskGroup.addTask {
                    let response = await self.refreshRemoteData(item, collectMetrics: finalMetrics)
                    return response
                }
            }
            
            var responses: [PhishInfo] = []
            for await response in taskGroup {
                guard !isCanceled else {
                    return responses
                }
                let result = response
                onQueue.async {
                    requestCompleted?(result)
                }
                responses.append(result)
            }
            return responses
        }
    }
}
