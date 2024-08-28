//
//  YandexSQIPipeline.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 28.08.2024.
//

import Foundation
import Alamofire
import AlamofireImage
import Vision
import AppKit

class YandexSQIPipeline: PhishingPipelineObject {
    func execute(data remoteObject: any StrictRemote) async -> any StrictRemote {
        let accurate = false
        
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
}
