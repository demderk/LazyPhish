//
//  URLInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 04.03.2024.
//
import Foundation
import Alamofire
import RegexBuilder
import Vision
import AlamofireImage
import AppKit

/*  Ребят, если кто-то из моих будующих работодаделей или менторов это увидит.
 Не бейте палками ради бога. Я про эти стаил гайды нормального ничего не нашел.
 Мне даже спросить про них не у кого ;(( */

enum PhishRequestMetric {
    case yandexSQI
    case OPR
    case whois
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

class PhishRequest {
        
    public func refreshRemoteData(_ base: StrictRemote) async -> PhishInfo {
        await refreshRemoteData(base, collectMetrics: [.yandexSQI, .OPR, .whois])
    }
        
    public func refreshRemoteData(
        _ base: StrictRemote,
        collectMetrics: Set<PhishRequestMetric>
    ) async -> PhishInfo {
        let remote = await withTaskGroup(
            of: StrictRemote.self,
            returning: StrictRemote.self) { taskGroup in
                var result: StrictRemote = base
                for item in collectMetrics {
                    switch item {
                    case .OPR:
                        taskGroup.addTask { [self] in await processOPR(base) }
                    case .whois:
                        taskGroup.addTask { [self] in await processWhois(base)}
                    case .yandexSQI:
                        taskGroup.addTask { [self] in await processYandexSQI(base) }
                    }
                }
                for await item in taskGroup {
                    result.remote.append(remote: item.remote)
                }
                return result
            }
        // FIXME: Чек на нулл
        return remote as! PhishInfo
    }
    
    internal func processWhois(_ remoteObject: StrictRemote) async -> StrictRemote {
        var result = remoteObject
        do {
            let connection = WhoisConnection()
            let whois = try await connection.lookup(host: remoteObject.host)
            result.remote.whois = .success(value: whois)
            return result
        } catch let error as WhoisError {
            result.remote.whois = .failed(error: error)
            return result
        }
        catch {
            if let nserr = POSIXErrorCode(rawValue: Int32((error as NSError).code)) {
                if case .ECANCELED = nserr {
                    result.remote.whois = .failed(error: WhoisError.timeout)
                    return result
                }
            }
            result.remote.whois = .failed(error: WhoisError.unknown(error))
            return result
        }
    }
        
    internal func processYandexSQI(
        _ remoteObject: StrictRemote,
        accurate: Bool = false)
    async -> StrictRemote {
        
        var remote: StrictRemote = remoteObject
        
        let response = await AF.request("https://yandex.ru/cycounter?\(remoteObject.host)")
            .serializingImage(inflateResponseImage: false).result
        
        switch response {
        case .success(let success):
            if let input = success.cgImage(forProposedRect: .none, context: .none, hints: nil) {
                guard let image = input.cropping(to: CGRect(x: 30, y: 0, width: 58, height: 31))?
                    .increaseContrast()
                else {
                    remote.remote.yandexSQI = .failed(error: YandexSQIError.yandexSQICroppingError)
                    return remote
                }
                let vision = VNImageRequestHandler(cgImage: image)
                
                let imageRequest = VNRecognizeTextRequest()
                imageRequest.recognitionLevel = .fast
                var recognized: String?
                
                // Fast algorithm check
                do {
                    try vision.perform([imageRequest])
                    if let result = imageRequest.results {
                        let data = result.compactMap { listC in
                            return listC.topCandidates(1).first?.string
                        }
                        if !data.isEmpty {
                            recognized = data[0]
                        }
                    }
                } catch {
                    remote.remote.yandexSQI = .failed(
                        error: YandexSQIError.yandexSQIVisionPerformError(error))
                    return remote
                }
                
                // Accurate algorithm check if enabled
                do {
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
                } catch {
                    remote.remote.yandexSQI = .failed(
                        error: YandexSQIError.yandexSQIVisionPerformError(error))
                    return remote
                }
                
                guard let output = recognized else {
                    remote.remote.yandexSQI = .failed(
                        error: YandexSQIError.yandexSQIVisionNotRecognized(
                            image: NSImage(cgImage: image, size: .zero)))
                    return remote
                }
                
                if let sqi = Int(output.replacing(" ", with: "")) {
                    var result = remoteObject
                    result.remote.yandexSQI = .success(value: sqi)
                    return result
                } else {
                    remote.remote.yandexSQI = .failed(error: YandexSQIError.yandexSQIVisionNotRecognized(
                        image: NSImage(cgImage: image, size: .zero)))
                    return remote
                }
            }
            remote.remote.yandexSQI = .failed(error: YandexSQIError.yandexSQIVisionNotRecognizedUnknown)
            return remote
        case .failure(let failure):
            remote.remote.yandexSQI = .failed(error: YandexSQIError.yandexSQIRequestError(parent: failure))
            return remote
        }
    }
    
    internal func getOPRKey() throws -> String {
//        if let path = Bundle.main.path(forResource: "Authority", ofType: "plist") {
//            if let data = try? Data(contentsOf: URL(filePath: path)) {
//                if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
//                    as? [String: String] {
//                    if let result = plist["OPRKey"] {
//                        return result
//                    }
//                }
//            }
//        }
        if !KeyService.inited {
            KeyService.refreshAllKeys()
        }
        if let opr = KeyService.OPRKey {
            return opr
        }
        throw RequestCriticalError.authorityAccessError
    }
    
    internal func processOPR(_ remoteObject: StrictRemote) async -> StrictRemote {
        return await processOPR(remoteObjects: [remoteObject])[0]
    }
    
    // TODO: Array надо на Set заменить. Мы не знаем порядок элементов
    // В singleOPRRequest тоже порядок может меняться. Лучше контроллировать этот процесс
    func processOPR(remoteObjects: [StrictRemote]) async -> [StrictRemote] {
        if remoteObjects.count < 100 {
            return await singleOPRRequest(remoteObjects: remoteObjects)
        }
        let splitedRemote = remoteObjects.chunked(into: 100)
        
        let finalRemote = await withTaskGroup(
            of: [StrictRemote].self,
            returning: [StrictRemote].self
        ) { requestPool in
            for item in splitedRemote {
                // TODO: Weak Self?
                requestPool.addTask { [self] in 
                    await singleOPRRequest(remoteObjects: item)
                }
            }
            var result: [StrictRemote] = []
            for await request in requestPool {
                result.append(contentsOf: request)
            }
            return result
        }
        return finalRemote
    }
    
    func singleOPRRequest(remoteObjects: [StrictRemote]) async -> [StrictRemote] {
        var result: [StrictRemote] = []
        guard remoteObjects.count <= 100 else {
            for item in remoteObjects {
                var temp = item
                temp.remote.OPR = .failed(error: OPRError.singleRequestCountExceeded)
                result.append(temp)
            }
            return result
        }
        guard let apiKey = try? getOPRKey() else {
            for item in remoteObjects {
                var temp = item
                temp.remote.OPR = .failed(error: OPRError.apiKeyUnreachable)
                result.append(temp)
            }
            return result
        }
        var params: [String: String] = [:]
        for (n, item) in remoteObjects.enumerated() {
            params["domains[\(n)]"] = item.host
        }
        let headers: HTTPHeaders = [ "API-OPR": apiKey ]
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let request = AF.request(
            "https://openpagerank.com/api/v1.0/getPageRank",
            parameters: params,
            headers: headers
        )
        
        let afResult = request.serializingDecodable(OPRResponse.self, decoder: jsonDecoder)
        
        switch await afResult.result {
        case .success(let success):
            let response = success.response
            
            for item in response {
                guard var found = remoteObjects.first(
                    where: {
                        $0.host.lowercased() == item.domain.lowercased() ||
                        $0.host.lowercased() == "www.\(item.domain.lowercased())" }
                ) else {
                    fatalError(item.domain)
                }
                if let successResult = item as? OPRInfo {
                    found.remote.OPR = .success(value: successResult)
                    result.append(found)
                } else {
                    found.remote.OPR = .failed(
                        error: OPRError.remoteError(response: "[\(item.statusCode)] \(item.error)"))
                    result.append(found)
                }
            }
            return result
        case .failure(let error):
            for item in remoteObjects {
                var temp = item
                temp.remote.OPR = .failed(error: OPRError.requestError(underlyingError: error))
                result.append(temp)
            }
            return result
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
