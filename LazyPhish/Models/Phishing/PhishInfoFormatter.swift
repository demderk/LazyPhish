//
//  IPFormatDetector.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 15.04.2024.
//

import Foundation

enum FormatPreaction {
    case makeHttps
    case makeHttp

    func execute(_ input: String) -> String {
        switch self {
        case .makeHttps:
            return PhishInfoFormatter.makeHttps(url: input)
        case .makeHttp:
            return PhishInfoFormatter.makeHttp(url: input)
        }
    }
}

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

        let URLStr = url.host()!

        if (try? ipv4Regex.firstMatch(in: URLStr)) != nil {
            return true
        }
        if (try? ipv4RegexBin.firstMatch(in: URLStr)) != nil {
            return true
        }
        if (try? ipv4RegexBinDiv.firstMatch(in: URLStr)) != nil {
            return true
        }
        return false
    }

    static func validURL(_ urlString: String, preActions: Set<FormatPreaction> = []) throws -> URL {
        var input = urlString
        for action in preActions {
            input = action.execute(input)
        }
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParserError.requestIsEmpty
        }
        guard input.split(separator: ".").count > 1 else {
            throw ParserError.urlNotAWebRequest(url: urlString)
        }
        guard input.prefix(4) == "http" else {
            throw ParserError.urlNotAWebRequest(url: urlString)
        }
        guard let url = URL(string: input) else {
            throw ParserError.urlHostIsInvalid(url: urlString)
        }
        guard url.host() != nil else {
            throw ParserError.urlHostIsBroken(url: urlString)
        }

        return url
    }

    static func makeHttps(url: String) -> String {
        guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return url
        }
        guard url.prefix(8) == "https://" else {
            return url
        }
        return "https://\(url)"
    }

    static func makeHttp(url: String) -> String {
        guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return url
        }
        if url.prefix(7) == "http://" || url.prefix(8) == "https://" {
            return url
        }
        return "http://\(url)"
    }
}
