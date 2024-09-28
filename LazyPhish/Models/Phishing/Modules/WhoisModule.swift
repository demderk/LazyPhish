//
//  WhoisPipeline.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 28.08.2024.
//

import Foundation

class WhoisModule: RequestModule {
    var dependences: [any RequestModule] = []
    var status: ModuleStatus = .planned
    var whois: WhoisInfo?
    
    var date: Date? { whois?.creationDate }
    var dateText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        var text = "Creation data unavailable"
        var foundText = self.whois == nil ? "Whois is empty" : "Whois found"
        dateFormatter.locale = Locale(identifier: "en_US")
        if let date = self.whois?.creationDate {
            text = dateFormatter.string(from: date)
        }
        return text
    }
    
    private static var whoisSemaphore = Semaphore(count: 1)
    private static var sCount: UInt64 = 1

    func processWhois(_ remoteObject: RemoteInfo) async {
        var result = remoteObject
        do {
            let connection = WhoisConnection()
            let whois = try await connection.lookup(host: remoteObject.url.strictHost)
            self.whois = whois
            status = .completed
            return
        } catch let error as WhoisError {
            status = .failed(error: error)
            return
        } catch {
            if let nserr = POSIXErrorCode(rawValue: Int32((error as NSError).code)) {
                if case .ECANCELED = nserr {
                    status = .failed(error: WhoisError.timeout)
                    return
                }
            }
            status = .failed(error: WhoisError.unknown(error))
            return
        }
    }

    public func execute(remote: RemoteInfo) async {
        status = .executing
        await WhoisModule.whoisSemaphore.wait()
        await processWhois(remote)
        if WhoisModule.sCount < 50 {
            await WhoisModule.whoisSemaphore.signal(count: 10)
            WhoisModule.sCount += 10
        } else {
            await WhoisModule.whoisSemaphore.signal(count: 1)
        }
    }
}
