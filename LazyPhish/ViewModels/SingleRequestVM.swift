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
    @Published var lastRequest: PhishInfo?
    @Published var tagList: [MetricData] = []
    @Published var requestIsPending: Bool = false

    private var phishRequest: PhishRequestSingle?
    private var cardIsPresented: Bool = false
    
    func makeRequest() {
        let p = NeoPhishRequest()
        Task {
            let x = await p.executeRequest(url: try! StrictURL(
                url: request, preActions: [.makeHttp]),
                                           modules: [.opr, .whois, .sqi])
            print(x)
        }
//        if !request.isEmpty && !requestIsPending {
//            do {
//                requestIsPending = true
//                phishRequest = try PhishRequestSingle(request, preActions: [.makeHttp])
//                phishRequest?.refreshRemoteData { data in
//                    if !self.cardIsPresented {
//                        withAnimation {
//                            self.presentCard(data: data)
//                        }
//                    } else {
//                        self.presentCard(data: data)
//                    }
////                    self.cardIsPresented = true
//
//                }
//            } catch {
//                // TODO: Show error on page
//                print(error.localizedDescription)
//                errorText = error.localizedDescription
//            }
//        }
//        objectWillChange.send()
    }
    
    func presentCard(data: PhishInfo) {
        self.lastRequest = data
        self.requestIsPending = false
    }
}
