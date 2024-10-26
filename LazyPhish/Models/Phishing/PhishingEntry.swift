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
    var subDomains: String
    var prefixCount: String
    var isIP: String

    init(_ entry: PhishingEntry) {
        self.id = entry.id
        self.url = entry.url
        self.sqi = entry.sqi?.description ?? "SQI failed"
        self.opr = entry.opr?.description ?? "OPR failed"
        self.date = entry.dateText ?? (entry.whoisBlinded ? "Domain zone is blinded" : "Date parsing error")
        self.length = entry.urlLength.description
        self.subDomains = entry.subDomains.description
        self.prefixCount = entry.prefixCount.description
        self.isIP = entry.isIP ? "Yes" : "No"
    }

    static var csvHeader: String {
        let result = [
            "id",
            "host",
            "hostLength",
            "url",
            "urlLength",
            "sqi",
            "subDomains",
            "prefixCount",
            "isIP",
            "date",
            "dateFromNow",
            "opr",
            "isPhishing"
        ]
        return result.joined(separator: ",")
    }
}

struct PhishingEntry: Identifiable {
    var id: Int

    var host: String
    var hostLength: Int
    var url: String
    var urlLength: Int = -1
    var whoisFound: Bool = false
    var whoisBlinded: Bool = false
    var date: Date?
    var dateFromNow: TimeInterval?
    var dateText: String?
    var sqi: Int?
    var opr: Int?
    var subDomains: Int = 0
    var prefixCount: Int = 0
    var isIP: Bool = false

    var visual: VisualPhishingEntry { VisualPhishingEntry(self) }
}

extension PhishingEntry {

    init(fromRemote: RequestInfo) {
        host = fromRemote.host
        hostLength = host.count
        url = fromRemote.url.URL.description
        id = fromRemote.requestID ?? -1
        for module in fromRemote.modules {
            switch module {
            case let current as OPRModule:
                self.opr = current.rank
            case let current as SQIModule:
                self.sqi = current.yandexSQI
            case let current as WhoisModule:
                self.date = current.date
                self.dateFromNow = current.date?.timeIntervalSinceNow
                self.dateText = current.dateText
                self.whoisBlinded = current.blinded ?? false
                self.whoisFound = current.whois == nil ? false : true
            case let current as RegexModule:
                self.urlLength = current.urlLength
                self.subDomains = current.subdomainCount
                self.prefixCount = current.prefixCount
                self.isIP = current.isIP
            default:
                break
            }
        }
    }

    static var csvHeader: String {
        let result = [
            "id",
            "host",
            "url",
            "hostLength",
            "urlLength",
            "sqi",
            "subDomains",
            "prefixCount",
            "isIP",
            "whoisBlinded",
            "date",
            "dateFromNow",
            "opr",
            "isPhishing"
        ]
        return result.joined(separator: ",")
    }

    var csv: String {
        let result: [String] = [
            id.description,
            host,
            url,
            hostLength.description,
            urlLength.description,
            (sqi ?? -1).description,
            subDomains.description,
            prefixCount.description,
            isIP ? "1" : "0",
            whoisBlinded ? "1" : "0",
            date?.timeIntervalSince1970.description ?? "",
            dateFromNow?.description ?? "",
            (opr ?? -1).description,
            "0"
        ]
        return result.joined(separator: ",")
    }
}
