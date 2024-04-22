//
//  MLEntry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation

struct MLEntry {
    
    var isIP: RiskLevel
    var haveWhois: RiskLevel
    var creationDate: RiskLevel
    var urlLength: RiskLevel
    var yandexSQI: RiskLevel
    var OPR: RiskLevel
    var prefixCount: RiskLevel
    var subDomainCount: RiskLevel
    
    init(_ phishInfo: PhishInfo) {
        isIP = phishInfo.isIP ? .danger : .common
        haveWhois = phishInfo.whois == nil ? .danger : .common
        // FIXME: Creation date
        creationDate = .common
        switch phishInfo {
        case let phish where phish.urlLength < 54:
            urlLength = .common
        case let phish where phish.urlLength <= 75:
            urlLength = .suspicious
        case let phish where phish.urlLength > 75:
            urlLength = .danger
        default:
            fatalError("x")
        }
        yandexSQI = phishInfo.yandexSQI == nil ? .danger : .common
        OPR = phishInfo.OPRRank == nil ? .danger : .common
        switch phishInfo {
        case let phish where phish.prefixCount < 1:
            prefixCount = .common
        case let phish where phish.prefixCount == 1:
            prefixCount = .suspicious
        case let phish where phish.prefixCount > 1:
            prefixCount = .danger
        default:
            fatalError("x")
        }
        switch phishInfo {
        case let phish where phish.subDomainCount < 1:
            subDomainCount = .common
        case let phish where phish.subDomainCount == 1:
            subDomainCount = .suspicious
        case let phish where phish.subDomainCount > 1:
            subDomainCount = .danger
        default:
            fatalError("x")
        }
    }
}
