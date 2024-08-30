//
//  PhishRequestQuerry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation

actor Semaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(count: Int = 0) {
        self.count = count
    }

    func wait() async {
        count -= 1
        if count >= 0 { return }
        await withCheckedContinuation {
            waiters.append($0)
        }
    }

    func signal(count: Int = 1) {
        assert(count >= 1)
        self.count += count
        for _ in 0..<count {
            if waiters.isEmpty { return }
            waiters.removeFirst().resume()
        }
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
    
    //MARK: Main logic
   
    public func refreshRemoteData(
        onRequestComplete: ((PhishInfo) -> Void)?,
        onTaskComplete: @escaping (([PhishInfo]) -> Void),
        onQueue: DispatchQueue = DispatchQueue.main
    ) {
        Task {
            phishInfo = await refreshRemoteData(
                phishInfo,
                collectMetrics: [YandexSQIPipeline(),
                                 OPRPipeline(),
                                 WhoisPipeline()],
                requestCompleted: onRequestComplete)
            onQueue.async {
                onTaskComplete(self.phishInfo)
            }
        }
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
