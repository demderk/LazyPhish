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
    private(set) var phishInfo: [PhishInfo] = []
    private var whoisSemaphore = Semaphore(count: 1)
    private var mainSemaphore = Semaphore(count: 100)
    
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
    
    convenience init(_ urlStrings: String...) throws {
        try self.init(urlStrings)
    }
    
    override init() {
        
    }
    
    public func phishInfo(_ urlStrings: [String]) throws {
        phishInfo.append(contentsOf: try urlStrings.map({ try PhishInfo($0) }))
    }
    
    public func refreshRemoteData(
        onRequestComplete: ((PhishInfo) -> Void)?,
        onTaskComplete: @escaping (([PhishInfo]) -> Void),
        onQueue: DispatchQueue = DispatchQueue.main
    ) {
        Task {
            phishInfo = await refreshRemoteData(phishInfo, requestCompleted: onRequestComplete)
            onQueue.async {
                onTaskComplete(self.phishInfo)
            }
        }
    }
    
    var sCount: UInt64 = 1
    
    public override func processWhois(_ remoteObject: any StrictRemote) async -> any StrictRemote {
        await whoisSemaphore.wait()
        let x = await super.processWhois(remoteObject)
        if sCount < 50 {
            await whoisSemaphore.signal(count: 10)
            sCount += 10
        } else {
            await whoisSemaphore.signal(count: 1)
        }
        return x
    }
    
    override func refreshRemoteData(_ base: any StrictRemote, collectMetrics: Set<PhishRequestMetric>) async -> PhishInfo {
        await mainSemaphore.wait()
        let x = await super.refreshRemoteData(base, collectMetrics: collectMetrics)
        await mainSemaphore.signal()
        return x
    }
    
    private func refreshRemoteData(
        _ base: [StrictRemote],
        requestCompleted: ((PhishInfo) -> Void)? = nil,
        onQueue: DispatchQueue = DispatchQueue.main
    ) async -> [PhishInfo] {
        var remote = base
        remote = await processOPR(remoteObjects: remote)
        
        return await withTaskGroup(of: PhishInfo.self) { taskGroup in
            for item in remote {
                taskGroup.addTask {
                    let response = await self.refreshRemoteData(item, collectMetrics: [.yandexSQI, .whois])
                    return response
                }
            }
            
            var responses: [PhishInfo] = []
            for await response in taskGroup {
                // Получение whois нужно запускать обязательно последовательно, иначе оно падает.
                // let result = await self.refreshRemoteData(response, collectMetrics: [.whois])
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
