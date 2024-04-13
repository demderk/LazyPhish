//
//  PhishInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation
import SwiftWhois

struct PhishInfo {
    let url: URL

    var remote = PhishInfoRemote()

    var whois: WhoisData? { remote.whois.value ?? nil }
    var yandexSQI: Int? { remote.yandexSQI.value }
    var OPR: OPRInfo? { remote.OPR.value }

    var isIP: Bool { getURLIPMode(url) }
    var creationDate: Date? { whois?.creationDate != nil ? try? getDate(whois!.creationDate!) : nil }
    var OPRRank: Int? { OPR?.rank != nil ? Int((OPR?.rank)!) : nil }
    var OPRGrade: Decimal? { OPR?.pageRankDecimal }
    var host: String? { url.host() }
    var urlLength: Int { url.formatted().count }
    var prefixCount: Int { url.formatted().components(separatedBy: ["-"]).count - 1 }
    var subDomainCount: Int { url.formatted().components(separatedBy: ["."]).count - 2 }
    var hasErrors: Bool { remote.hasErrors }

    private func getDate(_ whoisDate: String) throws -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var res = dateFormatter.date(from: whoisDate)
        if res == nil {
            res = try? Date(whoisDate, strategy: .iso8601)
        }
        guard let result = res else {
            throw RequestError.dateFormatError
        }
        return result
    }

    private let URLIPv4Regex = try!
    Regex(#"(\d{1,3}\W{0,}[.]\W{0,}\d{1,3}\W{0,}[.]\W{0,}\d{1,3}\W{0,}[.]\W{0,}\d{1,3})"#)

    private let URLIPv4RegexBinary = try!
    Regex(#"0[xX][0-9a-fA-F]{8,}"#)

    private let URLIPv4RegexBinaryDiv = try!
    Regex(#"0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}"#)

    private func getURLIPMode(_ url: URL) -> Bool {
        if (try? URLIPv4Regex.firstMatch(in: url.formatted())) != nil {
            return true
        }
        if (try? URLIPv4RegexBinary.firstMatch(in: url.formatted())) != nil {
            return true
        }
        if (try? URLIPv4RegexBinaryDiv.firstMatch(in: url.formatted())) != nil {
            return true
        }
        return false
    }
}
