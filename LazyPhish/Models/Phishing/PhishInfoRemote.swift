//
//  PhishInfoRemote.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation
import SwiftWhois
import os

extension Logger {
    static let requestErrors = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: "Request Error")
    )
}

struct PhishInfoRemote {
    var whois: MetricStatus<WhoisInfo> = .planned { 
        didSet {
            if case .failed(let error) = whois {
                Logger.requestErrors.error("PhishRemoteError: \(error.localizedDescription)")
            }
        }
    }
    var yandexSQI: MetricStatus<Int> = .planned
    var OPR: MetricStatus<OPRInfo> = .planned
    
    var hasErrors: Bool {
        self.whois.error != nil ||
        self.yandexSQI.error != nil ||
        self.OPR.error != nil
    }
    
    var completed: Bool {
        if case .planned = whois {
            return false
        }
        if case .planned = yandexSQI {
            return false
        }
        if case .planned = OPR {
            return false
        }
        return true
    }
    
    mutating func forceAppend(remote: PhishInfoRemote) {
        self.whois = remote.whois
        self.yandexSQI = remote.yandexSQI
        self.OPR = remote.OPR
    }

    mutating func append(remote: PhishInfoRemote) {
        if case .planned = whois {
            self.whois = remote.whois
        }
        if case .planned = yandexSQI {
            self.yandexSQI = remote.yandexSQI
        }
        if case .planned = OPR {
            self.OPR = remote.OPR
        }
    }

}
