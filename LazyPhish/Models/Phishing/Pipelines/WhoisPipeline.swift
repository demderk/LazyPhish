//
//  WhoisPipeline.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 28.08.2024.
//

import Foundation

class WhoisPipeline: PhishingPipelineObject {
    private static var whoisSemaphore = Semaphore(count: 1)
    private static var sCount: UInt64 = 1

    func processWhois(data remoteObject: any StrictRemote) async -> any StrictRemote {
        var result = remoteObject
        do {
            let connection = WhoisConnection()
            let whois = try await connection.lookup(host: remoteObject.host)
            result.remote.whois = .success(value: whois)
            return result
        } catch let error as WhoisError {
            result.remote.whois = .failed(error: error)
            return result
        }
        catch {
            if let nserr = POSIXErrorCode(rawValue: Int32((error as NSError).code)) {
                if case .ECANCELED = nserr {
                    result.remote.whois = .failed(error: WhoisError.timeout)
                    return result
                }
            }
            result.remote.whois = .failed(error: WhoisError.unknown(error))
            return result
        }
    }
    
    public func execute(data remoteObject: any StrictRemote) async -> any StrictRemote {
        await WhoisPipeline.whoisSemaphore.wait()
        let x = await processWhois(data: remoteObject)
        if WhoisPipeline.sCount < 50 {
            await WhoisPipeline.whoisSemaphore.signal(count: 10)
            WhoisPipeline.sCount += 10
        } else {
            await WhoisPipeline.whoisSemaphore.signal(count: 1)
        }
        return x
    }
}
