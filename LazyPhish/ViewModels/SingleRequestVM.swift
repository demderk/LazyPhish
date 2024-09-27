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
    @Published var lastRequest: RemoteInfo?
    @Published var requestIsPending: Bool = false

    private var phishRequest: PhishRequestSingle?
    private var cardIsPresented: Bool = false

    func makeRequest() {
        let phishRequest = NeoPhishRequest()
        if let url = try? StrictURL(url: request, preActions: [.makeHttp]) {
            Task {
                await MainActor.run {
                    withAnimation {
                        requestIsPending = true
                    }
                }
                let response = await phishRequest.executeRequest(url: url, modules: [.opr, .regex, .sqi, .whois])
                await MainActor.run {
                    withAnimation {
                        requestIsPending = false
                        lastRequest = response
                    }
                }
            }
        } else {
            errorText = "Invalid Request"
        }
    }
}
