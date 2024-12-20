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
    @Published var lastRequest: RemoteRequest?
    @Published var requestIsPending: Bool = false
    @Published var statusText: String = ""

    private var cardIsPresented: Bool = false

    func makeRequest() {
        let phishRequest = PhishRequest()
        statusText = ""
        if let url = try? StrictURL(url: request, preActions: [.makeHttp]) {
            Task {
                await MainActor.run {
                    withAnimation {
                        requestIsPending = true
                    }
                }
                let response = await phishRequest.executeRequest(
                    url: url,
                    modules: [.MLBundle])
                await MainActor.run {
                    withAnimation {
                        requestIsPending = false
                        lastRequest = response
                        if let successRequest = lastRequest {
                            let failedModulesCount = successRequest.modules.count(where: { $0.failed })
                            let succeedModules = successRequest.modules.count - failedModulesCount
                            statusText = "\(succeedModules) modules succeed, \(failedModulesCount) failed"
                        }
                        var mlmod: MLModule = MLModule()
                        let x = mlmod.predictPhishing(input: PhishingEntry(fromRemote: response))
                        print(x.isPhishingProbability)
                    }
                }
            }
        } else {
            errorText = "Invalid Request"
        }
    }
}
