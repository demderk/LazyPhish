//
//  PhishRequestQuerry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation

class PhishRequestQuerry : PhishRequest {
    var oprCache: [URL:OPRInfo] = [:]
    
    // PhishRequestQuerry caches OPR by default
    override func getOPR(_ url: URL) async throws -> OPRInfo {
        return try await self.getOPR(url, ignoreCache: false)
    }
    
    
    override func getOPR(_ url: [URL]) async throws -> [OPRInfo] {
        return try await self.getOPR(url, ignoreCache: false)
    }
    
    // TODO: Init
    
    // TODO: refreshRemoteData Closure
    
    // TODO: refreshRemoteData Combine
    
    func refreshRemoteData(_ base: [PhishInfo]) async -> Result<[PhishInfo],RequestError> {
        let requestOPR = base.map { $0.url }
        
        // FIXME: Check errors please 👉👈
        try! await cacheOPR(requestOPR)
        
        let res = await withTaskGroup(of: PhishInfo.self) { taskGroup in
            for item in base {
                taskGroup.addTask {
                    print(Date().formatted())
                    let response = await self.refreshRemoteData(item)
                    switch response {
                    case .success(let success):
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
        
        return .success(res)
    }
    
    func getOPR(_ url: URL, ignoreCache: Bool) async throws -> OPRInfo {
        if ignoreCache {
            return try await super.getOPR(url)
        }
        return try await getOPRCached([url])[0]
    }
    
    func getOPR(_ url: [URL], ignoreCache: Bool) async throws -> [OPRInfo] {
        if ignoreCache {
            return try await super.getOPR(url)
        }
        return try await getOPRCached(url)
    }
    
    func cacheOPR(_ url: [URL]) async throws {
        let _ = try await getOPRCached(url)
    }
    
    func getOPRCached(_ url: [URL]) async throws -> [OPRInfo] {
        var requested: [URL] = url
        var cache: [OPRInfo] = []
        for (n,item) in requested.enumerated() {
            if let found = oprCache[item] {
                cache.append(found)
                requested.remove(at: n)
            }
        }
        guard !requested.isEmpty else {
            return cache
        }
        let resultwurl = try await getOPRURL(requested)
        oprCache.merge(resultwurl) { (_, new) in new }
        return oprCache.values.map({$0})
    }
    
    func getOPRURL(_ url: [URL]) async throws -> [URL:OPRInfo] {
        let res = try await super.getOPR(url)
        var dict: [URL:OPRInfo] = [:]
        
        for (n,item) in url.enumerated() {
            dict[item] = res[n]
        }
        
        return dict
    }
}
