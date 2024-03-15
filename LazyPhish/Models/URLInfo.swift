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
import Vision
import AlamofireImage
import Combine

enum IPMode: Int {
    case url = -1
    case ip = 1
}

enum RiskLevel {
    case common
    case suspicious
    case danger
}



class URLInfo {
    private let URLIPv4Regex = try!
    Regex(#"(\d{1,3}\W{0,}[.]\W{0,}\d{1,3}\W{0,}[.]\W{0,}\d{1,3}\W{0,}[.]\W{0,}\d{1,3})"#)
    
    private let URLIPv4RegexBinary = try!
    Regex(#"0[xX][0-9a-fA-F]{8,}"#)
    
    private let URLIPv4RegexBinaryDiv = try!
    Regex(#"0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}\W{0,}[.]\W{0,}0[xX][0-9a-fA-F]{2}"#)
    
    public var whoisDomain: String { url.formatted().components(separatedBy: ["."]).suffix(2).joined(separator: ".") }
    public var urlLength: Int { url.formatted().count }
    public var prefixCount: Int { url.formatted().components(separatedBy: ["-"]).count - 1 }
    public var subDomainCount: Int { url.formatted().components(separatedBy: ["."]).count - 2 }
    
    private let url: URL
    
    public var publicSubscriptions = Set<AnyCancellable>()
    
    @Published private(set) var isIP: IPMode = .url
    @Published private(set) var whoisData: WhoisData? = nil
    @Published private(set) var creationDate: Date? = nil
    @Published private(set) var yandexSQI: Int? = nil
    @Published private(set) var OPRRank: Int? = nil
    @Published private(set) var OPRGrade: Decimal? = nil
    
    private(set) var MLEntry: MLEntry?
    
    init(_ url: URL) {
        self.url = url
        self.isIP = getURLIPMode(url)
        
    }
    
    @MainActor
    public func refreshRemoteData(onComplete: @escaping () -> Void, onError: @escaping ([RequestError]) -> Void) {
        Task {
            let result = await refreshRemoteData()
            if let errors = result {
                onError(errors)
                return
            }
            onComplete()
        }
    }
    
    @MainActor
    public func refreshRemoteData() async -> [RequestError]? {
        var errors: [RequestError] = []
        async let whois: WhoisData? = getWhois(whoisDomain)
        async let sqi = getYandexSQIImage()
        async let opr = getOPR()
        
        do {
            let result = try await (whois: whois, sqi: sqi, opr: opr)
            self.yandexSQI = result.sqi
            if let date = result.whois?.creationDate {
                creationDate = try getDate(date)
            }
            if let oprRank = result.opr.rank {
                self.OPRRank = Int(oprRank)
            }
            self.OPRGrade = result.opr.page_rank_decimal
        } catch let error as RequestError {
            errors.append(error)
        } catch {
            
        }
        guard errors.isEmpty else {
            return errors
        }
        return nil
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
    
    private func getWhois(_ url: String) async -> WhoisData? {
        return try? await SwiftWhois.lookup(domain: url)
    }
    
    private func getYandexSQI() async throws -> Int {
        let response = try await AF.request("https://webmaster.yandex.ru/siteinfo/?host=\(url.formatted())", method: .get)
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
    
    private func getOPRKey() throws -> String {
        if let path = Bundle.main.path(forResource: "Authority", ofType: "plist") {
            if let data = try? Data(contentsOf: URL(filePath: path)) {
                if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
                    if let result = plist["OPRKey"] {
                        return result
                    }
                }
            }
        }
        throw RequestError.authorityAccessError
    }
    
    private func getOPR() async throws -> OPRInfo {
        let apiKey = try getOPRKey()
        
        let params: [String: String] = [
            "domains[0]": url.formatted()
        ]
        
        let headers: HTTPHeaders = [
            "API-OPR": apiKey
        ]
        
        let afResult = await AF.request("https://openpagerank.com/api/v1.0/getPageRank",parameters: params ,headers: headers).serializingDecodable(OPRResponse.self).result
        
        switch afResult {
        case .success(let success):
            return success.response[0]
        case .failure(let failure):
            print(failure)
            throw RequestError.OPRError
        }
    }
    
    private func getYandexSQIImage() async throws -> Int {
        let response = AF.request("https://yandex.ru/cycounter?\(self.url.formatted())").serializingImage(inflateResponseImage: false)
        
        if let image = try await response.value.cgImage(forProposedRect: .none, context: .none, hints: nil) {
            let vision = VNImageRequestHandler(cgImage: image)
            let imageRequest = VNRecognizeTextRequest()
            try vision.perform([imageRequest])
            if let result = imageRequest.results {
                let data = result.compactMap { listC in
                    listC.topCandidates(1).first?.string
                }
                guard !data.isEmpty else {
                    throw RequestError.yandexSQIImageParseError
                }
                if let sqi = Int(data[0].replacing(" ", with: "")) {
                    return sqi
                }
            }
        }
        throw RequestError.yandexSQIImageParseError
    }
}
