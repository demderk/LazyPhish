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
    public func refreshRemoteData(_ base: PhishInfo) async -> Result<PhishInfo, RequestError> {
        let remote = try! await withThrowingTaskGroup(of: PhishInfoRemote.self, returning: PhishInfoRemote.self) { taskGroup in
            var result = PhishInfoRemote()
            taskGroup.addTask { [self] in
                do {
                    guard let host = base.host else {
                        throw RequestError.urlHostIsInvalid(url: base.url)
                    }
                    let whois: WhoisData? = try await getWhois(host)
                    return PhishInfoRemote(whois: .success(value: whois))
                } catch let error as RequestError {
                    return PhishInfoRemote(whois: .failed(error: error))
                } catch {
                    return PhishInfoRemote(whois: .failed(error: .unknownError(parent: error)))
                }
            }
            taskGroup.addTask { [self] in
                do {
                    let YSQI: Int = try await getYandexSQI(base.url)
                    return PhishInfoRemote(yandexSQI: .success(value: YSQI))
                } catch let error as RequestError {
                    return PhishInfoRemote(yandexSQI: .failed(error: error))
                } catch {
                    return PhishInfoRemote(yandexSQI: .failed(error: .unknownError(parent: error)))
                }
            }
            taskGroup.addTask { [self] in
                do {
                    let OPR: OPRInfo = try await getOPR(base.url)
                    return PhishInfoRemote(OPR: .success(value: OPR))
                } catch let error as RequestError {
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

    internal func getYandexSQI(_ url: URL, accurate: Bool = false) async throws -> Int {
        guard let host = url.host() else {
            throw RequestError.urlHostIsInvalid(url: url)
        }

        let response = await AF.request("https://yandex.ru/cycounter?\(host)")
            .serializingImage(inflateResponseImage: false).result

        switch response {
        case .success(let success):
            if let input = success.cgImage(forProposedRect: .none, context: .none, hints: nil) {
                guard let image = input.cropping(to: CGRect(x: 30, y: 0, width: 58, height: 31))?.increaseContrast() else {
                    throw RequestError.yandexSQICroppingError
                }
                let vision = VNImageRequestHandler(cgImage: image)

                // Fast algorithm check
                let imageRequest = VNRecognizeTextRequest()
                imageRequest.recognitionLevel = .fast
                var recognized: String?
                try vision.perform([imageRequest])
                if let result = imageRequest.results {
                    let data = result.compactMap { listC in
                        return listC.topCandidates(1).first?.string
                    }
                    if !data.isEmpty {
                        recognized = data[0]
                    }
                }

                // Accurate algorithm check if enabled
                if recognized == nil && accurate {
                    let accurateRequest = VNRecognizeTextRequest()
                    accurateRequest.recognitionLevel = .accurate
                    try vision.perform([accurateRequest])
                    if let result = accurateRequest.results {
                        let data = result.compactMap { listC in
                            return listC.topCandidates(1).first?.string
                        }
                        if !data.isEmpty {
                            recognized = data[0]
                        }
                    }
                }

                guard let output = recognized else {
                    throw RequestError.yandexSQIVisionNotRecognized(image: NSImage(cgImage: image, size: .zero))
                }

                if let sqi = Int(output.replacing(" ", with: "")) {
                    return sqi
                } else {
                    throw RequestError.yandexSQIVisionNotRecognized(image: NSImage(cgImage: image, size: .zero))
                }
            }
            throw RequestError.yandexSQIVisionNotRecognizedUnknown
        case .failure(let failure):
            throw RequestError.yandexSQIRequestError(parent: failure)
        }
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

        for (n, item) in url.enumerated() {
            guard let host = item.host() else {
                throw RequestError.urlHostIsInvalid(url: item)
            }
            params["domains[\(n)]"] = host
        }

        print(params)

        let headers: HTTPHeaders = [
            "API-OPR": apiKey
        ]

        let afResult = await AF.request("https://openpagerank.com/api/v1.0/getPageRank", parameters: params, headers: headers).serializingDecodable(OPRResponse.self).result

        switch afResult {
        case .success(let success):
            return success.response
        case .failure(let failure):
            throw RequestError.OPRError
        }
    }
}

extension CGImage {
    func increaseContrast() -> CGImage {
        let inputImage = CIImage(cgImage: self)
        let parameters = [
            "inputContrast": NSNumber(value: 2)
        ]
        let outputImage = inputImage.applyingFilter("CIColorControls", parameters: parameters)

        let context = CIContext(options: nil)
        let img = context.createCGImage(outputImage, from: outputImage.extent)!
        return img
    }
}
