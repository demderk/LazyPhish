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

enum RiskLevel {
    case common
    case suspicious
    case danger
}

enum MetricStatus<T> {
    case planned
    case success(value: T)
    case failed(error: RequestError)
    
    var value: T? {
        switch self {
        case .planned:
            return nil
        case .success(let value):
            return value
        case .failed:
            return nil
        }
    }
    
    var error: RequestError? {
        switch self {
        case .planned:
            return nil
        case .success:
            return nil
        case .failed(let value):
            return value
        }
    }
}

struct PhishInfoRemote {
    var whois: MetricStatus<WhoisData?> = .planned
    var yandexSQI: MetricStatus<Int> = .planned
    var OPR: MetricStatus<OPRInfo> = .planned
    
    var hasErrors: Bool {
        self.whois.error != nil ||
        self.yandexSQI.error != nil ||
        self.OPR.error != nil
    }
    
    mutating func forceAppend(remote: PhishInfoRemote) {
        self.whois = remote.whois
        self.yandexSQI = remote.yandexSQI
        self.OPR = remote.OPR
    }
    
    mutating func append(remote: PhishInfoRemote) throws {
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

struct PhishInfo {
    let url: URL
    
    var remote = PhishInfoRemote()
    
    var whois: WhoisData? { remote.whois.value ?? nil }
    var yandexSQI: Int? { remote.yandexSQI.value }
    var OPR: OPRInfo? { remote.OPR.value }
    
    var isIP: Bool { getURLIPMode(url) }
    var creationDate: Date? { whois?.creationDate != nil ? try? getDate(whois!.creationDate!) : nil }
    var OPRRank: Int? { OPR?.rank != nil ? Int((OPR?.rank)!) : nil }
    var OPRGrade: Decimal? { OPR?.page_rank_decimal }
    var whoisDomain: String { url.formatted().components(separatedBy: ["."]).suffix(2).joined(separator: ".") }
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
        if let _ = try? URLIPv4Regex.firstMatch(in: url.formatted()) {
            return true
        }
        if let _ = try? URLIPv4RegexBinary.firstMatch(in: url.formatted()) {
            return true
        }
        if let _ = try? URLIPv4RegexBinaryDiv.firstMatch(in: url.formatted()) {
            return true
        }
        return false
    }
}

class PhishRequestBase {
    public var publicSubscriptions = Set<AnyCancellable>()
    
    private(set) var MLEntry: MLEntry?
    private(set) var phishInfo: PhishInfo
    private let url: URL
    
    init(_ url: URL) {
        self.url = url
        phishInfo = PhishInfo(url: url)
    }
    
    @MainActor
    public func refreshRemoteData(onComplete: @escaping () -> Void, onError: @escaping (RequestError) -> Void) {
        Task {
            let result = await refreshRemoteData(phishInfo)
            switch result {
            case .success(let success):
                phishInfo = success
                onComplete()
            case .failure(let failure):
                onError(failure)
            }
        }
    }
    
    public func refreshRemoteData(_ base: PhishInfo) async -> Result<PhishInfo,RequestError> {
        let remote = try! await withThrowingTaskGroup(of: PhishInfoRemote.self, returning: PhishInfoRemote.self) { taskGroup in
            var result = PhishInfoRemote()
            taskGroup.addTask { [self] in
                print(Date().formatted())
                do {
                    let whois: WhoisData? = try await getWhois(base.whoisDomain)
                    return PhishInfoRemote(whois: .success(value: whois))
                } catch let error as RequestError{
                    return PhishInfoRemote(whois: .failed(error: error))
                } catch {
                    return PhishInfoRemote(whois: .failed(error: .unknownError(parent: error)))
                }
            }
            taskGroup.addTask { [self] in
                print(Date().formatted())
                do {
                    let YSQI: Int = try await getYandexSQIImage(base.url)
                    return PhishInfoRemote(yandexSQI: .success(value: YSQI))
                } catch let error as RequestError{
                    return PhishInfoRemote(yandexSQI: .failed(error: error))
                } catch {
                    return PhishInfoRemote(yandexSQI: .failed(error: .unknownError(parent: error)))
                }
            }
            taskGroup.addTask { [self] in
                print(Date().formatted())
                do {
                    let OPR: OPRInfo = try await getOPR(base.url)
                    return PhishInfoRemote(OPR: .success(value: OPR))
                } catch let error as RequestError{
                    return PhishInfoRemote(OPR: .failed(error: error))
                } catch {
                    return PhishInfoRemote(OPR: .failed(error: .unknownError(parent: error)))
                }
            }
            for try await item in taskGroup {
               try result.append(remote: item)
            }
            return result
        }
        print("done")
        return .success(PhishInfo(url: base.url, remote: remote))
    }
    
    private func getWhois(_ url: String) async throws -> WhoisData? {
        return try await SwiftWhois.lookup(domain: url)
    }
    
    @available(*, deprecated)
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
    
    private func getYandexSQIImage(_ url: URL) async throws -> Int {
        let response = AF.request("https://yandex.ru/cycounter?\(url.formatted())").serializingImage(inflateResponseImage: false)
        
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
    
    private func getOPR(_ url: URL) async throws -> OPRInfo {
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
}
