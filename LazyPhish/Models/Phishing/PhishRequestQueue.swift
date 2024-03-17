//
//  PhishRequestQuerry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation

class PhishRequestQueue : PhishRequest {
    var oprCache: [URL:OPRInfo] = [:]
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
    // TODO: Init
    
    // TODO: refreshRemoteData Closure
    // TODO: refreshRemoteData Combine
    
    public func refreshRemoteData(onTaskComplete: ((PhishInfo) -> Void)?) {
        Task {
            let result = await refreshRemoteData(phishInfo, requestCompleted: onTaskComplete)
        }
    }
    
    func refreshRemoteData(_ base: [PhishInfo], requestCompleted: ((PhishInfo) -> Void)? = nil) async -> [PhishInfo] {
        let requestOPR = base.map { $0.url }
        
        // FIXME: Check errors please 👉👈
        try! await cacheOPR(urls: requestOPR)
        
        let res = await withTaskGroup(of: PhishInfo.self) { taskGroup in
            for item in base {
                taskGroup.addTask {
                    print(Date().formatted())
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
            return responses
        }
        
        return res
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
        let _ = try await getOPRCached(urls: url)
    }
    
    func getOPRCached(urls requested: [URL]) async throws -> [OPRInfo] {
        var cache: [OPRInfo] = []
        var send: [URL] = []
        for (n,item) in requested.enumerated() {
            if let found = oprCache[item] {
                cache.append(found)
                continue
            }
            send.append(item)
        }
        guard !send.isEmpty else {
            return cache
        }
        let resultwurl = try await getOPRURL(urls: send)
        oprCache.merge(resultwurl) { (_, new) in new }
        return oprCache.values.map({$0})
    }
    
    func getOPRURL(urls url: [URL]) async throws -> [URL:OPRInfo] {
        let res = try await super.getOPR(urls: url)
        var dict: [URL:OPRInfo] = [:]
        
        for (n,item) in url.enumerated() {
            dict[item] = res[n]
        }
        
        return dict
    }
}
