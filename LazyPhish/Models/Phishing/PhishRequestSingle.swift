//
//  PhishRequestSingle.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import Foundation

class PhishRequestSingle: PhishRequest {
    private(set) var phishInfo: PhishInfo
    
    init(_ url: String) throws {
        phishInfo = try PhishInfo(url)
    }
    
    init(_ url: String, preActions: Set<FormatPreaction>) throws {
        phishInfo = try PhishInfo(url, preActions: preActions)
    }
    
    func refreshRemoteData(
        onTaskComplete: ((PhishInfo) -> Void)?,
        onQueue: DispatchQueue = DispatchQueue.main
    ) {
        Task {
            let result = await super.refreshRemoteData(phishInfo)
            onQueue.async {
                if let onTaskComplete {
                    onTaskComplete(result)
                }
            }
        }
    }
}
