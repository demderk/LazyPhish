//
//  PhishingEntry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.10.2024.
//

import Foundation

struct VisualPhishingEntry: Identifiable {
    var id: Int
    var url: String
    var date: String
    var sqi: String
    var opr: String
    var length: String
    var hostLength: String
    var subDomains: String
    var prefixCount: String
    var isIP: String

    init(_ entry: PhishingEntry) {
        self.id = entry.id
        self.url = entry.url
        self.sqi = entry.sqi.description
        self.opr = entry.opr.description
        self.date = entry.dateText ?? (entry.whoisBlinded ? "Domain zone is blinded" : "Date parsing error")
        self.length = entry.urlLength.description
        self.hostLength = entry.hostLength.description
        self.subDomains = entry.subDomains.description
        self.prefixCount = entry.prefixCount.description
        self.isIP = entry.isIP ? "Yes" : "No"
    }
}

struct PhishingEntry: Identifiable, Codable {
    var id: Int

    var host: String
    var hostLength: Int
    var url: String
    var urlLength: Int = -1
    var whoisFound: Bool = false
    var whoisBlinded: Bool = false
    var date: Date?
    var dateText: String?
    var sqi: Int = -1
    var opr: Int = -1
    var subDomains: Int = 0
    var prefixCount: Int = 0
    var isIP: Bool = false
    var isPhishing: Int = 0

    var whoisBlindedInt: Int {
        whoisBlinded ? 1 : 0
    }
    
    var dateFromNow: TimeInterval {
        (date?.timeIntervalSinceNow ?? 1) * -1
    }
    var visual: VisualPhishingEntry { VisualPhishingEntry(self) }
    
    static var csvHeader: [String] {
        let result = [
            "id",
            "host",
            "hostLength",
            "url",
            "urlLength",
            "whoisFound",
            "whoisBlinded",
            "date",
            "dateText",
            "sqi",
            "opr",
            "subDomains",
            "prefixCount",
            "isPhishing"
        ]
        return result
    }
    
    enum CodingKeys: String, CodingKey {
        case id, host, hostLength, url, urlLength, whoisFound, whoisBlinded, date, dateText, sqi, opr, subDomains, prefixCount, isPhishing
    }
}

extension PhishingEntry {

    init(fromRemote: RemoteRequest) {
        host = fromRemote.host
        hostLength = -1
        url = fromRemote.url.URL.description
        id = fromRemote.requestID ?? -1
        for module in fromRemote.modules {
            switch module {
            case let current as OPRModule:
                self.opr = current.rank ?? -1
            case let current as SQIModule:
                self.sqi = current.yandexSQI ?? -1
            case let current as WhoisModule:
                self.date = current.date
                self.dateText = current.dateText
                self.whoisBlinded = current.blinded
                self.whoisFound = current.whoisFound
            case let current as RegexModule:
                self.urlLength = current.urlLength
                self.hostLength = current.hostLength
                self.subDomains = current.subdomainCount
                self.prefixCount = current.prefixCount
                self.isIP = current.isIP
            default:
                break
            }
        }
    }
}
