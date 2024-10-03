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

struct PhishTableEntry: Identifiable {
    var id: Int
    
    var host: String
    var opr, sqi, length, subDomains, prefixCount: Int?
    var isIP: Bool?
    var date: String?
}

extension PhishTableEntry {
    init(fromRemote: RequestInfo) {
        host = fromRemote.url.strictHost
        id = fromRemote.requestID ?? -1
        for module in fromRemote.modules {
            switch module {
            case let current as OPRModule:
                self.opr = current.OPRInfo?.pageRankInteger
            case let current as SQIModule:
                self.sqi = current.yandexSQI
            case let current as WhoisModule:
                self.date = current.dateText
            case let current as RegexModule:
                self.length = current.urlLength
                self.subDomains = current.subdomainCount
                self.prefixCount = current.prefixCount
                self.isIP = current.isIP
            default:
                break
            }
        }
    }
}

extension RequestInfo: Identifiable {
    var id: Int? { self.requestID }
}

class MultiRequestVM: ObservableObject {
    @Published var requestText = ""
    @Published var remotes: [RequestInfo] = []
    @Published var tableContent: [PhishTableEntry] = []
    @Published var CSVExportIsPresented = false
    @Published var RAWExportIsPresented = false
    @Published var readyForExport = false
    @Published var busy = false
    @Published var isCanceled = false
    @Published var status: RemoteStatus = .planned
    @Published var statusIconName = "checkmark.circle.fill"
    @Published var statusText = "Ready"
    @Published var linesWithErrors = 0
    @Published var linesWithWarnings = 0
    @Published var totalParsed = 0
    
    private var lastUrlsCount = 0
    
    var resultingDocument: PhishFile = PhishFile([])
    var RAWResultingDocument: RawPhishFile = RawPhishFile([])
    var ignoreWrongLines: Bool = true
    
    func onModuleFinished(remote: RequestInfo, module: RequestModule) {
        if case .completedWithErrors = module.status {
            linesWithWarnings += 1
        }
        if let found = tableContent.firstIndex(where: { $0.id == remote.requestID }) {
            tableContent[found] = PhishTableEntry(fromRemote: remote)
        } else {
            tableContent.append(PhishTableEntry(fromRemote: remote))
        }
    }
    
    func onRequestFinished(remote: RequestInfo) {
        switch remote.status {
        case .completedWithErrors:
            linesWithErrors += 1
        default:
            break
        }
        totalParsed += 1
        statusText = "Processing | \(totalParsed) of \(lastUrlsCount)"
    }
    
    @MainActor
    func sendRequestQuerry() {
        let urls: [String] = requestText
            .components(separatedBy: .newlines)
            .compactMap({ $0.isEmpty ? nil : $0 })
        withAnimation {
            processUI()
        }
        lastUrlsCount = urls.count
        Task {
            let requestQueue = NeoPhishRequestQueue()
            requestQueue.phishURLS = urls.map({try! .init(url: $0, preActions: [.makeHttp])})
            let x = await requestQueue.executeAll(
                modules: [.opr, .regex, .sqi, .whois],
                onModuleFinished: onModuleFinished,
                onRequestFinished: onRequestFinished)
            await MainActor.run {
                withAnimation {
                    self.completeUI()
                }
            }
        }
        
    }
    
    func processUI() {
        readyForExport = false
        tableContent.removeAll()
        linesWithWarnings = 0
        lastUrlsCount = 0
        linesWithErrors = 0
        totalParsed = 0
        self.busy = true
        self.isCanceled = false
        self.statusText = "Processing request..."
        self.statusIconName = "timer"
    }
    
    func cancel() {
        isCanceled = true
    }
    
    func completeUI() {
        self.busy = false
        if isCanceled {
            self.status = .canceled
            self.statusText = "Run Canceled | Processed \(totalParsed) of \(lastUrlsCount)"
            self.statusIconName = "play.slash.fill"
        } else {
            if linesWithErrors > 0 {
                failedUI()
            } else if linesWithWarnings > 0 {
                completeWithErrorsUI()
            } else {
                self.status = .completed
                self.statusText = "Completed Successfully"
                self.statusIconName = "checkmark.circle.fill"
            }
        }
    }
    
    func completeWithErrorsUI() {
        self.busy = false
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
//        resultingDocument = PhishFile(engine.phishInfo.map({ $0.getMLEntry()! }))
        CSVExportIsPresented = true
    }
    
    func exportCSVRAW() {
//        RAWResultingDocument = RawPhishFile(engine.phishInfo)
        RAWExportIsPresented = true
    }
    
}
