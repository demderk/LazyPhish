//
//  URLInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 04.03.2024.
//
import Foundation
import SwiftWhois
import Alamofire
import RegexBuilder
import Vision
import AlamofireImage
import AppKit

class PhishRequest {
    public func refreshRemoteData(_ base: PhishInfo) async -> Result<PhishInfo,RequestError> {
        let remote = try! await withThrowingTaskGroup(of: PhishInfoRemote.self, returning: PhishInfoRemote.self) { taskGroup in
            var result = PhishInfoRemote()
            taskGroup.addTask { [self] in
                print(Date().formatted())
                do {
                    guard let host = base.host else {
                        throw RequestError.urlHostIsInvalid(url: base.url)
                    }
                    let whois: WhoisData? = try await getWhois(host)
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
                    let YSQI: Int = try await getYandexSQI(base.url)
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
        return .success(PhishInfo(url: base.url, remote: remote))
    }
    
    internal func getWhois(_ url: String) async throws -> WhoisData? {
        return try await SwiftWhois.lookup(domain: url)
    }
    
    internal func getYandexSQI(_ url: URL) async throws -> Int {
        guard let host = url.host() else {
            throw RequestError.urlHostIsInvalid(url: url)
        }
        
        let response = AF.request("https://yandex.ru/cycounter?\(host)")
            .serializingImage(inflateResponseImage: false)
        if let image = try await response.value.cgImage(forProposedRect: .none, context: .none, hints: nil) {
            let vision = VNImageRequestHandler(cgImage: image)
            let imageRequest = VNRecognizeTextRequest()
            imageRequest.recognitionLevel = .fast
            imageRequest.usesLanguageCorrection = false
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
    
    internal func getOPRKey() throws -> String {
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
    
    internal func getOPR(_ url: URL) async throws -> OPRInfo {
        return try await getOPR(urls: [url])[0]
    }
    
    internal func getOPR(urls url: [URL]) async throws -> [OPRInfo] {
        let apiKey = try getOPRKey()
        
        var params: [String: String] = [:]
        
        for (n,item) in url.enumerated() {
            guard let host = item.host() else {
                throw RequestError.urlHostIsInvalid(url: item)
            }
            params["domains[\(n)]"] = host
        }
        
        let headers: HTTPHeaders = [
            "API-OPR": apiKey
        ]
        
        let afResult = await AF.request("https://openpagerank.com/api/v1.0/getPageRank",parameters: params ,headers: headers).serializingDecodable(OPRResponse.self).result
        
        
        switch afResult {
        case .success(let success):
            print(success.response)
            return success.response
        case .failure(let failure):
            print(failure)
            throw RequestError.OPRError
        }
    }
}
