//
//  IPFormatDetector.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 15.04.2024.
//

import Foundation

final class PhishInfoFormatter {
    static let URLIPv4Regex: String =
    #"(\d{1,3}\W{0,}[.]\W{0,}\d{1,3}\W{0,}[.]\W{0,}\d{1,3}\W{0,}[.]\W{0,}\d{1,3})"#

    static let URLIPv4RegexBinary: String = #"0[xX][0-9a-fA-F]{8,}"#

    static let URLIPv4RegexBinaryDiv: String = #"""
0[xX][0-9a-fA-F]{2}\W{0,}[.] \
\W{0,}0[xX][0-9a-fA-F]{2}\W{0,}[.] \
\W{0,}0[xX][0-9a-fA-F]{2}\W{0,}[.] \
\W{0,}0[xX][0-9a-fA-F]{2}
"""#
    
    static func getURLIPMode(_ url: URL) -> Bool {
        guard let ipv4Regex = try? Regex(URLIPv4Regex),
              let ipv4RegexBin = try? Regex(URLIPv4RegexBinary),
              let ipv4RegexBinDiv = try? Regex(URLIPv4RegexBinaryDiv)
        else {
            // TODO: Нужно что-то с регексом придумать
            fatalError("REGEX ERROR")
        }
        
        if (try? ipv4Regex.firstMatch(in: url.formatted())) != nil {
            return true
        }
        if (try? ipv4RegexBin.firstMatch(in: url.formatted())) != nil {
            return true
        }
        if (try? ipv4RegexBinDiv.firstMatch(in: url.formatted())) != nil {
            return true
        }
        return false
    }
    
    static func validURL(_ urlString: String) throws -> URL {
        guard urlString.contains("http://") || urlString.contains("https://") else {
            throw RequestError.urlNotAWebRequest(url: urlString)
        }
        guard let url = URL(string: urlString) else {
            throw RequestError.urlHostIsInvalid(url: urlString)
        }
        guard url.host() != nil else {
            throw RequestError.urlHostIsBroken(url: urlString)
        }
        return url
    }
    
    static func getDate(_ whoisDate: String) throws -> Date {
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
}
