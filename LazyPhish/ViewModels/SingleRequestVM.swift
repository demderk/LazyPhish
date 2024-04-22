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
    
    private var phishRequest: PhishRequestSingle?
    
    func makeRequest() {
        if !request.isEmpty {
            do {
                phishRequest = try PhishRequestSingle(request)
                phishRequest?.refreshRemoteData { data in
                    withAnimation {
                        self.lastRequest = data
                        self.tagList = Array(data.getMetricSet()!.values.sorted(by: { $0.risk > $1.risk }))
                    }
                }
            } catch {
                errorText = error.localizedDescription
            }
        }
        objectWillChange.send()
    }
}
