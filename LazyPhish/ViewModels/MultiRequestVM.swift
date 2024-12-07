//
//  MultiRequestVM.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import Foundation
import SwiftUI

class MultiRequestVM: ObservableObject {
    @Published var requestText = ""
    @Published var remotes: [RequestInfo] = []
    @Published var tableContent: [PhishingEntry] = []
    @Published var CSVExportIsPresented = false
    @Published var educationalExportIsPresented = false
    @Published var readyForExport = false
    @Published var busy = false
    @Published var isCanceled = false
    @Published var status: RemoteStatus = .planned
    @Published var statusIconName = "checkmark.circle.fill"
    @Published var statusText = "Ready"
    @Published var linesWithErrors = 0
    @Published var linesWithWarnings = 0
    @Published var totalParsed = 0

    var educationalFile: EducationFile!

    private var lastUrlsCount = 0
    private var queue = PhishRequestQueue()
    var reviseable: Bool {
        lastUrlsCount > 0
    }

//    var resultingDocument: PhishFile = PhishFile([])
    var ignoreWrongLines: Bool = true

    func onModuleFinished(remote: RequestInfo, module: RequestModule) {
//        if case .completedWithErrors = module.status {
//            linesWithWarnings += 1
//        }
        if let found = tableContent.firstIndex(where: { $0.id == remote.requestID }) {
            tableContent[found] = PhishingEntry(fromRemote: remote)
        } else {
            tableContent.append(PhishingEntry(fromRemote: remote))
        }
    }

    func onRequestFinished(remote: RequestInfo) {
        switch remote.status {
        case .completedWithErrors:
            linesWithWarnings += 1
        case .failed:
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

        var correctURLS: [StrictURL] =  []
        for (n, item) in urls.enumerated() {
            do {
                let correctDomain = try StrictURL(url: item, preActions: [.makeHttp])
                correctURLS.append(correctDomain)
            } catch _ as ParserError {
                badRequest(n+1)
                return
            } catch {
                badRequest(n+1)
            }
        }
        queue.phishURLS = correctURLS

        withAnimation {
            processUI()
        }

        lastUrlsCount = correctURLS.count

        Task { [self] in
            await queue.executeAll(
                modules: [.whois],
                onModuleFinished: onModuleFinished,
                onRequestFinished: onRequestFinished)
            await MainActor.run {
                withAnimation {
                    self.completeUI()
                }
            }
        }
    }

    func reviseModuleFinished (remote: RequestInfo, module: RequestModule) {

    }

    func reviseRequestFinished(remote: RequestInfo) {
        totalParsed += 1
        statusText = "Revising | \(totalParsed) of \(lastUrlsCount)"
        if let found = tableContent.firstIndex(where: { $0.id == remote.requestID }) {
            if case .completed = remote.status {
                linesWithWarnings -= 1
                tableContent[found] = PhishingEntry(fromRemote: remote)
            }
        } else {
            tableContent.append(PhishingEntry(fromRemote: remote))
        }
    }

    func reviseRequestQuerry() {
        startReviseUI()
        Task { [self] in
            await queue.reviseLastRequest(
                onModuleFinished: reviseModuleFinished,
                onRequestFinished: reviseRequestFinished)
            await MainActor.run {
                endReviseUI()
            }
        }
    }

    private func startReviseUI() {
        self.busy = true
        self.isCanceled = false
        totalParsed = 0
        lastUrlsCount = linesWithWarnings + linesWithErrors
        self.statusText = "Processing request..."
        self.statusIconName = "timer"
    }

    private func endReviseUI() {
        self.busy = false
        self.isCanceled = false
        self.statusText = "Revision complete"
        self.statusIconName = "checkmark.circle.fill"
    }

    private func processUI() {
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

    private func cancel() {
        isCanceled = true
    }

    private func completeUI() {
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
        if tableContent.count > 0 { readyForExport = true }
    }

    private func completeWithErrorsUI() {
        self.busy = false
        self.status = .completedWithErrors
        self.statusText = "Completed With Warnings"
        self.statusIconName = "checkmark.circle.fill"

    }

    private func failedUI() {
        self.status = .failed
        self.statusText = "Completed With Errors"
    }

    private func badRequest(_ lineNumber: Int) {
        self.status = .failed
        self.statusIconName = "xmark.circle.fill"
        self.statusText = "Wrong url at line \(lineNumber)"
    }

    private func exportCSV() {
     //   resultingDocument = PhishFile(engine.phishInfo.map({ $0.getMLEntry()! }))
        CSVExportIsPresented = true
    }

    func exportEducationalFile() {
        educationalFile = EducationFile(tableContent)
        educationalExportIsPresented = true
    }

}
