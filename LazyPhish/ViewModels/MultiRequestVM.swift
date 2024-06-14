//
//  MultiRequestVM.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import Foundation
import SwiftUI

extension PhishInfo: Identifiable {
    // Я в этом сооооооооовсем не уверен
    var id: Int { self.requestID ?? Int.random(in: 0...Int.max) }
}

extension PhishInfo {
    var sortSqiInt: Int { self.yandexSQI ?? -1 }
    var sortOprInt: Int { self.OPRRank ?? -1 }
    var sortHaveWhois: Int { self.whois == nil ? 0 : 1 }
    var sortIsIP: Int { self.isIP ? 1 : 0 }
    var sortDate: Date { self.creationDate ?? Date(timeIntervalSince1970: 0) }
}

class MultiRequestVM: ObservableObject {
    @Published var requestText = ""
    @Published var tableContent: [PhishInfo] = []
    @Published var CSVExportIsPresented = false
    @Published var RAWExportIsPresented = false
    @Published var readyForExport = false
    @Published var bussy = false
    @Published var status: RemoteStatus = .planned
    @Published var statusIconName = "checkmark.circle.fill"
    @Published var statusText = "Ready"
    @Published var linesWithErrors = 0
    @Published var linesWithWarnings = 0
    @Published var totalParsed = 0
    
    private var engine = PhishRequestQueue()
    
    var resultingDocument: PhishFile = PhishFile([])
    var RAWResultingDocument: RawPhishFile = RawPhishFile([])
    var ignoreWrongLines: Bool = true
    
    @MainActor
    func sendRequestQuerry() {
        let urls: [String] = requestText.components(separatedBy: .newlines)
            .compactMap({ $0.isEmpty ? nil : $0 })
        var urlsUUIDS: [Int: String] = [:]
        var id = 0
        for url in urls {
            urlsUUIDS[id] = url
            id += 1
        }
        guard !urls.isEmpty else {
            return
        }
        do {
            engine = try PhishRequestQueue(urlsUUIDS, preActions: [.makeHttp])
        } catch let error as ParserError {
            var errorMessage = "Parser error"
            switch error {
            case .urlHostIsInvalid(let url):
                if let num = urls.firstIndex(of: url) {
                    errorMessage = "Swift host parse error."
                    errorMessage += "  Line \(num+1)."
                }
            case .urlNotAWebRequest(let url):
                errorMessage = "Not a web request."
                if let num = urls.firstIndex(of: url) {
                    errorMessage += "  Line \(num+1)."
                }
            case .urlHostIsBroken(let url):
                errorMessage = "Host is invalid."
                if let num = urls.firstIndex(of: url) {
                    errorMessage += " Line \(num+1)."
                }
            default:
                break
            }
            self.status = .failed
            self.statusText = "Run Failed | \(errorMessage)"
            self.statusIconName = "xmark.circle.fill"
            return
        } catch {
            self.status = .failed
            self.statusText = "Run Failed | \(error)"
            self.statusIconName = "xmark.circle.fill"
            return
        }
        processUI()
        engine.refreshRemoteData { [self] data in
            tableContent.append(data)
            totalParsed += 1
            statusText = "Processing | \(totalParsed) of \(urls.count)"
            switch data.remoteStatus {
            case.completedWithErrors:
                linesWithWarnings += 1
            case.failed:
                linesWithErrors += 1
            default:
                break
            }
        } onTaskComplete: { [self] arr in
                self.bussy = false
                self.readyForExport = true
                self.tableContent.sort(by: { $0.id < $1.id })
            withAnimation {
                if arr.contains(where: {$0.remoteStatus == .completedWithErrors}) {
                    completeWithErrorsUI()
                }
                if arr.contains(where: {$0.remoteStatus == .failed}) {
                    failedUI()
                    return
                }
                completeUI()
            }
        }
    }
    
    func processUI() {
        readyForExport = false
        tableContent.removeAll()
        linesWithWarnings = 0
        linesWithErrors = 0
        totalParsed = 0
        self.bussy = true
        self.statusText = "Processing..."
        self.statusIconName = "timer"
    }
    
    func completeUI() {
        self.bussy = false
        self.status = .completed
        self.statusText = "Completed Successfully"
        self.statusIconName = "checkmark.circle.fill"
    }
    
    func completeWithErrorsUI() {
        self.bussy = false
        self.status = .completedWithErrors
        self.statusText = "Completed With Warnings"
        self.statusIconName = "checkmark.circle.fill"
        
    }
    
    func failedUI() {
        self.status = .failed
        self.statusText = "Completed With Errors"
        self.statusIconName = "xmark.circle.fill"
    }
    
    func exportCSV() {
        resultingDocument = PhishFile(engine.phishInfo.map({ $0.getMLEntry()! }))
        CSVExportIsPresented = true
    }
    
    func exportCSVRAW() {
        RAWResultingDocument = RawPhishFile(engine.phishInfo)
        RAWExportIsPresented = true
    }
    
}
