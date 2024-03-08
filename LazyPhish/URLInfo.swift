//
//  URLInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 04.03.2024.
//
import Foundation
import SwiftWhois
import SwiftSoup
import Alamofire
import RegexBuilder

enum IPMode: Int {
    case url = -1
    case ip = 1
    
}

enum RiskLevel {
    case common
    case suspicious
    case danger
}

struct MLEntry {
    var isIP: Bool
    var creationDate: RiskLevel
    var urlLength: RiskLevel
}

enum RequestError: Error {
    case dateFormatError
    case yandexSQICaptchaError
    case yandexSQIUnderfined(response: String)
    
    var localizedDescription: String {
        switch self {
        case .dateFormatError:
            "Whois date formatted incorectly."
        case .yandexSQICaptchaError:
            "Yandex SQL provider requires Captcha."
        case .yandexSQIUnderfined(let response):
            "Yandex SQL underfined error."
        default:
            "..."
        }
    }
}

class URLInfo {
    private let URLIPv4Regex = try!
    Regex(#"(\d{1,3}\W{0,}[.]\W{0,}\d{1,3}\W{0,}[.]\W{0,}\d{1,3}\W{0,}[.]\W{0,}\d{1,3})"#)
    
    private let URLIPv4RegexBinary = try!
    Regex(#"0[xX][0-9a-fA-F]{8,}"#)
    
    private let URLIPv4RegexBinaryDiv = try!
    Regex(#"0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}"#)
    
    private let url: URL
    
    private(set) var isIP: IPMode = .url
    private(set) var whoisData: WhoisData? = nil
    private(set) var creationDate: Date? = nil
    private(set) var yandexSQI: Int? = nil
    
    public var urlLength: Int { url.formatted().count }
    public var prefixCount: Int { url.formatted().components(separatedBy: ["-"]).count - 1 }
    public var subDomainCount: Int { url.formatted().components(separatedBy: ["."]).count - 2 }
    
    private(set) var MLEntry: MLEntry?
    
    init(_ url: URL) {
        self.url = url
        self.isIP = getURLIPMode(url)
    }
    
    @MainActor
    public func refreshRemoteData(onComplete: @escaping () -> Void, onError: @escaping ([RequestError]) -> Void) {
        Task {
            var errors: [RequestError] = []
            
            let whois: WhoisData? = await getWhois(url)
            if let date = whois?.creationDate {
                creationDate = try? getDate(date)
            }
            
            do {
                self.yandexSQI = try await getYandexSQI()
            } catch let error as RequestError {
                errors.append(error)
            }
            guard errors.isEmpty else {
                onError(errors)
                return
            }
            onComplete()
        }
    }
    
    private func getURLIPMode(_ url: URL) -> IPMode {
        if let _ = try? URLIPv4Regex.firstMatch(in: url.formatted()) {
            return IPMode.ip
        }
        if let _ = try? URLIPv4RegexBinary.firstMatch(in: url.formatted()) {
            return IPMode.ip
        }
        if let _ = try? URLIPv4RegexBinaryDiv.firstMatch(in: url.formatted()) {
            return IPMode.ip
        }
        return IPMode.url
    }
    
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
    
    private func getWhois(_ url: URL) async -> WhoisData? {
        return try? await SwiftWhois.lookup(domain: url.formatted())
    }
    
    private func getYandexSQI() async throws -> Int {
        var response = try await AF.request("https://webmaster.yandex.ru/siteinfo/?host=\(url.formatted())", method: .get)
            .serializingString().value
        let valueAnchor = Reference<Substring>()
        let regex = Regex {
            #""sqi":"#
            Capture(as: valueAnchor) {
                OneOrMore {
                    .digit
                }
            }
        }
        guard let found = try? regex.firstMatch(in: response) else {
            let cRegex = Regex { "Captcha" }
            if let _ = try? cRegex.firstMatch(in: response) {
                throw RequestError.yandexSQICaptchaError
            } else {
                throw RequestError.yandexSQIUnderfined(response: response)
            }
        }
        if let result = Int(found[valueAnchor]) {
            return result
        } else {
            throw RequestError.yandexSQIUnderfined(response: response)
        }
    }
}
