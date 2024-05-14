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
    
    private var requestIsPending: Bool = false
    private var phishRequest: PhishRequestSingle?
    
    func makeRequest() {
        if !request.isEmpty && !requestIsPending{
            do {
                requestIsPending = true
                phishRequest = try PhishRequestSingle(request, preActions: [.makeHttp])
                phishRequest?.refreshRemoteData { data in
                    withAnimation {
                        self.lastRequest = data
                        self.tagList = Array(data.getMetricSet()!.values.sorted(by: { $0.risk > $1.risk }))
                        self.requestIsPending = false
                    }
                    let ML = PhishML()
                    print(ML.predictPhishing(input: (self.phishRequest?.phishInfo.getMLEntry())!))
                }
            } catch {
                // TODO: Show error on page
                print(error.localizedDescription)
                errorText = error.localizedDescription
            }
        }
//        objectWillChange.send()
    }
}
