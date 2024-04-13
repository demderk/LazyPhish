//
//  PhishRequestQuerry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation

class PhishRequestQueue: PhishRequest {
    var oprCache: [String: OPRInfo] = [:]
    var phishInfo: [PhishInfo] = []
    
    var phishURLS: [URL] {
        get {
            return phishInfo.map { $0.url }
        }
        set {
            phishInfo = newValue.map({ PhishInfo(url: $0) })
        }
    }
    
    init(_ urls: [URL]) {
        phishInfo.append(contentsOf: urls.map({ PhishInfo(url: $0) }))
    }
    
    override init() {
        
    }
    
    convenience init(_ urls: URL...) {
        self.init(urls)
    }
    
    // PhishRequestQuerry caches OPR by default
    override func getOPR(_ url: URL) async throws -> OPRInfo {
        return try await self.getOPR(url, ignoreCache: false)
    }
    
    override func getOPR(urls url: [URL]) async throws -> [OPRInfo] {
        return try await self.getOPR(urls: url, ignoreCache: false)
    }
    
    // TODO: refreshRemoteData Closure on Error
    
    public func refreshRemoteData(onTaskComplete: ((PhishInfo) -> Void)?) {
        Task {
            let result = await refreshRemoteData(phishInfo, requestCompleted: onTaskComplete)
        }
    }
    
    var lastRequest: UInt64 = 0
    
    var requestLock: NSLock = NSLock()
    
    override func refreshRemoteData(_ base: PhishInfo) async -> Result<PhishInfo, RequestError> {
        requestLock.withLock {
            lastRequest += 250
        }
        print(lastRequest)
        try! await Task.sleep(nanoseconds: lastRequest * 1000000)
        return await super.refreshRemoteData(base)
    }
    
    func refreshRemoteData(_ base: [PhishInfo], requestCompleted: ((PhishInfo) -> Void)? = nil) async -> [PhishInfo] {
        let requestOPR = base.map { $0.url }
        
        // FIXME: Check errors please 👉👈
        try! await cacheOPR(urls: requestOPR)
        
        return await withTaskGroup(of: PhishInfo.self) { taskGroup in
            for item in base {
                taskGroup.addTask {
                    let response = await self.refreshRemoteData(item)
                    switch response {
                    case .success(let success):
                        DispatchQueue.main.async {
                            requestCompleted?(success)
                        }
                        return success
                    case .failure(let failure):
                        print(failure)
                        return item
                    }
                }
            }
            
            var responses: [PhishInfo] = []
            for await response in taskGroup {
                responses.append(response)
            }
            defer {
                oprCache.removeAll()
                lastRequest = 0
            }
            return responses
        }
    }
    
    func getOPR(_ url: URL, ignoreCache: Bool) async throws -> OPRInfo {
        if ignoreCache {
            return try await super.getOPR(url)
        }
        return try await getOPRCached(urls: [url])[0]
    }
    
    func getOPR(urls url: [URL], ignoreCache: Bool) async throws -> [OPRInfo] {
        if ignoreCache {
            return try await super.getOPR(urls: url)
        }
        return try await getOPRCached(urls: url)
    }
    
    func cacheOPR(urls url: [URL]) async throws {
        _ = try await getOPRCached(urls: url)
    }
    
    func getOPRCached(urls requested: [URL]) async throws -> [OPRInfo] {
        var cache: [OPRInfo] = []
        var send: [URL] = []
        // MARK: ERROR
        let hosts = requested.map({ $0.host()! })
        for item in hosts {
            if let found = oprCache[item] {
                cache.append(found)
                continue
            }
            send.append(URL(string: "http://\(item)")!)
        }
        guard !send.isEmpty else {
            return cache
        }
        let resultwurl = try await getOPRURL(urls: send)
        for i in resultwurl where oprCache[i.key] == nil {
            oprCache[i.key] = i.value
        }
        for item in resultwurl {
            cache.append(item.value)
        }
        return cache
        
    }
    
    func getOPRURL(urls url: [URL]) async throws -> [String: OPRInfo] {
        let response = try await super.getOPR(urls: url)
        
        var result: [String: OPRInfo] = [:]
        
        for item in response {
            result[item.domain] = item
        }
        
        print(result.count)
        //        for (n,item) in url.enumerated() {
        //            dict[item] = res[n]
        //        }
        
        return result
    }
}
