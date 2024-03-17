//
//  PhishInfoRemote.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation
import SwiftWhois

struct PhishInfoRemote {
    var whois: MetricStatus<WhoisData?> = .planned
    var yandexSQI: MetricStatus<Int> = .planned
    var OPR: MetricStatus<OPRInfo> = .planned
    
    var hasErrors: Bool {
        self.whois.error != nil ||
        self.yandexSQI.error != nil ||
        self.OPR.error != nil
    }
    
    mutating func forceAppend(remote: PhishInfoRemote) {
        self.whois = remote.whois
        self.yandexSQI = remote.yandexSQI
        self.OPR = remote.OPR
    }
    
    mutating func append(remote: PhishInfoRemote) throws {
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