//
//  PhishInfoRemote.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation
import os

enum RemoteStatus {
    case planned
    case completedWithErrors
    case completed
    case failed
    case canceled
}

struct PhishInfoRemote {
    var whois: MetricStatus<WhoisInfo> = .planned { 
        didSet {
            if case .failed(let error) = whois {
                if error.isCritical {
                    Logger.whoisRequestLogger.warning("[WHOIS] [WARNING] \(error.localizedDescription)")
                } else {
                    Logger.whoisRequestLogger.info("[WHOIS] [INFO] \(error.localizedDescription)")
                }
            }
        }
    }
    var yandexSQI: MetricStatus<Int> = .planned {
        didSet {
            if case .failed(let error) = yandexSQI {
                if error.isCritical {
                    Logger.yandexSQIRequestLogger.warning(
                        "[YandexSQI] [WARNING] \(error.localizedDescription)")
                } else {
                    Logger.yandexSQIRequestLogger.trace(
                        "[YandexSQI] [INFO] \(error.localizedDescription)")
                }
            }
        }
    }
    var OPR: MetricStatus<OPRInfo> = .planned {
        didSet {
            if case .failed(let error) = OPR {
                if error.isCritical {
                    Logger.OPRRequestLogger.warning("[OPR] [WARNING] \(error.localizedDescription)")
                } else {
                    Logger.OPRRequestLogger.info("[OPR] [INFO] \(error.localizedDescription)")
                }
            }
        }
    }
    
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
    
    var status: RemoteStatus {
        var current: RemoteStatus = .planned
        if completed {
            current = .completed
            if let critical = whois.error {
                current = critical.isCritical ? .failed : .completedWithErrors
            }
            if let critical = yandexSQI.error {
                current = critical.isCritical ? .failed : .completedWithErrors
            }
            if let critical = OPR.error {
                current = critical.isCritical ? .failed : .completedWithErrors
            }
        }
        return current
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
