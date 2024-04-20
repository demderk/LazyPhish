//
//  MultiRequestVM.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import Foundation

class MultiRequestVM: ObservableObject {
    @Published var requestText = ""
    @Published var tableContent: [PhishTableEntry] = []

    private var engine = PhishRequestQueue()

    @MainActor
    func sendRequestQuerry() {
        let urls: [String] = requestText.components(separatedBy: .newlines)
            .compactMap({ $0.isEmpty ? nil : $0 })
        tableContent.removeAll()
        var id = 0
        engine = try! PhishRequestQueue(urls)
        engine.refreshRemoteData { [self] data in
            tableContent.append(PhishTableEntry(id: id, phishInfo: data))
            id += 1
        }
    }
    
}
