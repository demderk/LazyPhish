//
//  PhishRequestQuerry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation

class PhishRequestQueue: PhishRequest {
    var phishInfo: [PhishInfo] = []
    
    init(_ urlStrings: [String] ) throws {
        phishInfo.append(contentsOf: try urlStrings.map({ try PhishInfo($0) }))
    }
    
    init(urls: [URL]) throws {
        phishInfo.append(contentsOf: try urls.map({ try PhishInfo(url: $0) }))
    }
    
    override init() {
        
    }
    
    convenience init(_ urlStrings: String...) throws {
        try self.init(urlStrings)
    }
    
    // PhishRequestQuerry caches OPR by default
//    override func getOPR(_ url: URL) async throws -> OPRInfo {
//        return try await self.getOPR(url, ignoreCache: false)
//    }
//    
//    override func getOPR(urls url: [URL]) async throws -> [OPRInfo] {
//        return try await self.getOPR(urls: url, ignoreCache: false)
//    }
    
    // TODO: refreshRemoteData Closure on Error
    
    public func refreshRemoteData(onTaskComplete: ((PhishInfo) -> Void)?) {
        Task {
            _ = await refreshRemoteData(phishInfo, requestCompleted: onTaskComplete)
        }
    }
        
    override func refreshRemoteData(
        _ base: StrictRemote,
        collectMetrics: Set<PhishRequestMetric>)
    async -> PhishInfo {
        return await super.refreshRemoteData(base, collectMetrics: collectMetrics)
    }
    
    func refreshRemoteData(
        _ base: [StrictRemote],
        requestCompleted: ((PhishInfo) -> Void)? = nil
    ) async -> [PhishInfo] {
        var remote = base
        remote = await processOPR(remoteObjects: remote)
        
        return await withTaskGroup(of: PhishInfo.self) { taskGroup in
            for item in remote {
                taskGroup.addTask {
                    let response = await self.refreshRemoteData(item, collectMetrics: [.yandexSQI])
                    return response
                }
            }
            
            var responses: [PhishInfo] = []
            for await response in taskGroup {
                // Получение whois нужно запускать обязательно последовательно, иначе оно падает.
                let result = await self.refreshRemoteData(response, collectMetrics: [.whois])
                DispatchQueue.main.async {
                    requestCompleted?(result)
                }
                responses.append(result)
            }
            return responses
        }
    }
}
