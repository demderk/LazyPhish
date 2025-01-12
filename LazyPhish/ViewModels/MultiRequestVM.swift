//
//  MultiRequestVM.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import Foundation
import SwiftUI

enum UIRemoteError {
    case anyError
}

class MultiRequestVM: ObservableObject {
    @Published var requestText = ""
    @Published var remotes: [RemoteRequest] = []
    @Published var tableContent: [PhishingEntry] = []
    @Published var CSVExportIsPresented = false
    @Published var educationalExportIsPresented = false
    @Published var readyForExport = false
    @Published var busy = false
    @Published var incompleteSetup = false
    @Published var isCanceled = false
    @Published var status: RemoteJobStatus = .planned
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
    
    private var currentTask: Task<(), Never>? = nil
    
//    var resultingDocument: PhishFile = PhishFile([])
    var ignoreWrongLines: Bool = true

    @MainActor
    func start() {
        guard KeyService.setupComplete else {
            incompleteSetup = true
            return
        }
        
        let urls: [String] = requestText
            .components(separatedBy: .newlines)
            .compactMap({ $0.isEmpty ? nil : $0 })

        var correctURLS: [StrictURL] =  []
        for (n, item) in urls.enumerated() {
            do {
                let correctDomain = try StrictURL(url: item, preActions: [.makeHttp])
                correctURLS.append(correctDomain)
            } catch _ as ParserError {
                UIBadRequest(n+1)
                return
            } catch {
                UIBadRequest(n+1)
            }
        }
        queue.phishURLS = correctURLS

        withAnimation {
            UIStartProcessing()
        }

        lastUrlsCount = correctURLS.count

        currentTask = Task { [self] in
            await queue.executeAll(
                modules: [.whois, .sqi, .opr, .regex],
                onModuleFinished: onModuleFinished,
                onRequestFinished: onRequestFinished)
            await MainActor.run {
                withAnimation {
                    self.UIFinishProcessing()
                }
            }
        }
    }
    
    func stop() {
        currentTask?.cancel()
        isCanceled = true
    }
    
    func revise() {
        UIStartRevise()
        Task { [self] in
            await queue.reviseLastRequest(
                onModuleFinished: onReviseModuleFinished,
                onRequestFinished: onReviseRequestFinished)
            await MainActor.run {
                UIEndRevise()
            }
        }
    }
    

    func exportEducationalFile() {
        educationalFile = EducationFile(tableContent)
        educationalExportIsPresented = true
    }
    
    private func exportCSV() {
        //   resultingDocument = PhishFile(engine.phishInfo.map({ $0.getMLEntry()! }))
        CSVExportIsPresented = true
    }
    
    
    
    // MARK: Request Handlers
    
    private func onModuleFinished(remote: RemoteRequest, module: RequestModule) {
        if let found = tableContent.firstIndex(where: { $0.id == remote.requestID }) {
            tableContent[found] = PhishingEntry(fromRemote: remote)
        } else {
            tableContent.append(PhishingEntry(fromRemote: remote))
        }
    }
    
    private func onRequestFinished(remote: RemoteRequest) {
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
    
    private func onReviseModuleFinished (remote: RemoteRequest, module: RequestModule) {

    }

    private func onReviseRequestFinished(remote: RemoteRequest) {
        totalParsed += 1
        statusText = "Revising | \(totalParsed) of \(lastUrlsCount)"
        if let found = tableContent.firstIndex(where: { $0.id == remote.requestID }) {
            if remote.status.isCompleted {
                linesWithWarnings -= 1
                tableContent[found] = PhishingEntry(fromRemote: remote)
            }
        } else {
            tableContent.append(PhishingEntry(fromRemote: remote))
        }
    }

    // MARK: UI Functions
    
    private func UICancel() {
        self.busy = false
        self.isCanceled = true
        self.statusText = "Execution Stoped"
        self.statusIconName = "stop.fill"
    }
    
    private func UIStartRevise() {
        self.busy = true
        self.isCanceled = false
        totalParsed = 0
        lastUrlsCount = linesWithWarnings + linesWithErrors
        self.statusText = "Processing request..."
        self.statusIconName = "timer"
    }

    private func UIEndRevise() {
        self.busy = false
        self.isCanceled = false
        self.statusText = "Revision complete"
        self.statusIconName = "checkmark.circle.fill"
    }

    private func UIStartProcessing() {
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

    private func UIFinishProcessing() {
        self.busy = false
        if isCanceled {
            self.status = .canceled
            self.statusText = "Run Canceled | Processed \(totalParsed) of \(lastUrlsCount)"
            self.statusIconName = "play.slash.fill"
        } else {
            if linesWithErrors > 0 {
                UIFail()
            } else if linesWithWarnings > 0 {
                UICompleteWithErrors()
            } else {
                self.status = .completed
                self.statusText = "Completed Successfully"
                self.statusIconName = "checkmark.circle.fill"
            }
        }
        if tableContent.count > 0 { readyForExport = true }
    }

    private func UICompleteWithErrors() {
        self.busy = false
        self.status = .completedWithErrors()
        self.statusText = "Completed With Warnings"
        self.statusIconName = "checkmark.circle.fill"

    }

    private func UIFail() {
//        self.status = .failed()
        self.statusText = "Completed With Errors"
    }

    private func UIBadRequest(_ lineNumber: Int) {
//        self.status = .failed
        self.statusIconName = "xmark.circle.fill"
        self.statusText = "Wrong url at line \(lineNumber)"
    }

}
