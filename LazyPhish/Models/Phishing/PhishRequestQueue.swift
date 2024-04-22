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
    
    public func refreshRemoteData(onTaskComplete: ((PhishInfo) -> Void)?) {
        Task {
            _ = await refreshRemoteData(phishInfo, requestCompleted: onTaskComplete)
        }
    }
    
    func refreshRemoteData(
        _ base: [StrictRemote],
        requestCompleted: ((PhishInfo) -> Void)? = nil,
        onQueue: DispatchQueue = DispatchQueue.main
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
                onQueue.async {
                    requestCompleted?(result)
                }
                responses.append(result)
            }
            return responses
        }
    }
}
