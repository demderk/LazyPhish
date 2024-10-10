//
//  SingleRequestViewModel.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.04.2024.
//

import Foundation
import SwiftUI

class SingleRequestViewModel: ObservableObject {
    @Published var request: String = ""
    @Published var errorText: String?
    @Published var lastRequest: RequestInfo?
    @Published var requestIsPending: Bool = false
    @Published var statusText: String = ""
    
    private var cardIsPresented: Bool = false

    func makeRequest() {
        let phishRequest = NeoPhishRequest()
        statusText = ""
        if let url = try? StrictURL(url: request, preActions: [.makeHttp]) {
            Task {
                await MainActor.run {
                    withAnimation {
                        requestIsPending = true
                    }
                }
                let response = await phishRequest.executeRequest(url: url, modules: [.opr, .regex, .sqi, .whois, .ml])
                await MainActor.run {
                    withAnimation {
                        requestIsPending = false
                        lastRequest = response
                        if let successRequest = lastRequest {
                            let failedModulesCount = successRequest.modules.count(
                                where: {if case .failed = $0.status {true} else {false}})
                            statusText =
                            "\(successRequest.modules.count - failedModulesCount) modules succeed, \(failedModulesCount) failed"
                        }
                    }
                }
            }
        } else {
            errorText = "Invalid Request"
        }
    }
}
