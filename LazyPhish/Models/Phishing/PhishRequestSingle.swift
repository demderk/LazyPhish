//
//  PhishRequestSingle.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import Foundation

//class PhishRequestSingle: PhishRequest {
//    private(set) var phishInfo: PhishInfo
//
//    init(_ url: URL) {
//        phishInfo = try! PhishInfo(url: url)
//    }
//
//    @MainActor
//    public func refreshRemoteData(
//        onComplete: @escaping () -> Void,
//        onError: @escaping (RequestError) -> Void
//    ) {
//        Task {
//            let result = await refreshRemoteData(phishInfo)
//            switch result {
//            case .success(let success):
//                phishInfo = success
//                onComplete()
//            case .failure(let failure):
//                onError(failure)
//            }
//        }
//    }
//}
