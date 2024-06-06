//
//  PhishInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation
import SwiftWhois

// guarantees of a mandatory host
protocol StrictURL {
    var url: URL { get }
    var host: String { get }
}

protocol StrictRemote: StrictURL {
    var remote: PhishInfoRemote { get set }
}

struct PhishInfo: StrictRemote {
    let url: URL

    var remote = PhishInfoRemote()

    var whois: WhoisInfo? { remote.whois.value ?? nil }
    var yandexSQI: Int? { remote.yandexSQI.value }
    var OPR: OPRInfo? { remote.OPR.value }

    var isIP: Bool { PhishInfoFormatter.getURLIPMode(url) }
    var creationDate: Date? { whois?.creationDate }
    var OPRRank: Int? { OPR?.rank != nil ? Int((OPR?.rank)!) : nil }
    var OPRGrade: Decimal? { OPR?.pageRankDecimal }
    var host: String { url.host()! } // 100% non-nil value is excepted
    var urlLength: Int { url.formatted().count }
    var prefixCount: Int { url.formatted().components(separatedBy: ["-"]).count - 1 }
    var subDomainCount: Int { url.formatted().components(separatedBy: ["."]).count - 2 }
    var hasErrors: Bool { remote.hasErrors }
    
    // Вроде как, нужно избегать конструкторов, которые могут вернуть ошибку... Так?
    // Инкапсулировал код формата PhishInfo, так как свифт не умеет вызывать
    // экземплярные методы.
    init(_ urlString: String) throws {
        url = try PhishInfoFormatter.validURL(urlString)
    }

    init(_ urlString: String, preActions: Set<FormatPreaction>) throws {
        url = try PhishInfoFormatter.validURL(urlString, preActions: preActions)
    }

    init(url: URL) throws {
        self.url = try PhishInfoFormatter.validURL(url.absoluteString)
    }
    
    init(_ urlString: String, remote: PhishInfoRemote) throws {
        url = try PhishInfoFormatter.validURL(urlString)
        self.remote = remote
    }

    init(url: URL, remote: PhishInfoRemote) throws {
        self.url = try PhishInfoFormatter.validURL(url.absoluteString)
        self.remote = remote
    }
    
    func getMLEntry() -> MLEntry? {
        if remote.completed {
            return MLEntry(self)
        }
        return nil
    }
}
