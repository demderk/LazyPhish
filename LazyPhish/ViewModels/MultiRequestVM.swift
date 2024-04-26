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
    @Published var CSVExportIsPresented = false
    @Published var readyForExport = false
    @Published var bussy = false
    
    private var engine = PhishRequestQueue()
    
    var resultingDocument: PhishFile = PhishFile([])
    
    @MainActor
    func sendRequestQuerry() {
        let urls: [String] = requestText.components(separatedBy: .newlines)
            .compactMap({ $0.isEmpty ? nil : $0 })
        guard !urls.isEmpty else {
            return
        }
        readyForExport = false
        bussy = true
        tableContent.removeAll()
        var id = 0
        engine = try! PhishRequestQueue(urls, preActions: [.makeHttp])
        engine.refreshRemoteData { [self] data in
            tableContent.append(PhishTableEntry(id: id, phishInfo: data))
            id += 1
        } onTaskComplete: { _ in
            self.bussy = false
            self.readyForExport = true
        }
    }
    
    func exportCSV() {
        resultingDocument = PhishFile(engine.phishInfo.map({ $0.getMLEntry()! }))
        CSVExportIsPresented = true
    }
    
}
