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

class SQIModule: RequestModule {
    var dependences: [any RequestModule] = []
    var status: ModuleStatus = .planned
    var yandexSQI: Int?

    func execute(remote: RemoteInfo) async {
        status = .executing
        let accurate = false

        let response = await AF.request("https://yandex.ru/cycounter?\(remote.url.strictHost)")
            .serializingImage(inflateResponseImage: false).result

        switch response {
        case .success(let success):
            if let input = success.cgImage(forProposedRect: .none, context: .none, hints: nil) {
                guard let image = input.cropping(to: CGRect(x: 30, y: 0, width: 58, height: 31))?
                    .increaseContrast()
                else {
                    status = .failed(error: YandexSQIError.yandexSQICroppingError)
                    return
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
                    status = .failed(
                        error: YandexSQIError.yandexSQIVisionPerformError(error))
                    return
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
                    status = .failed(
                        error: YandexSQIError.yandexSQIVisionPerformError(error))
                    return
                }

                guard let output = recognized else {
                    status = .failed(
                        error: YandexSQIError.yandexSQIVisionNotRecognized(
                            image: NSImage(cgImage: image, size: .zero)))
                    return
                }

                if let sqi = Int(output.replacing(" ", with: "")) {
                    yandexSQI = sqi
                    status = .completed
                    return
                } else {
                    status = .failed(error: YandexSQIError.yandexSQIVisionNotRecognized(
                        image: NSImage(cgImage: image, size: .zero)))
                    return
                }
            }
            status = .failed(error: YandexSQIError.yandexSQIVisionNotRecognizedUnknown)
            return
        case .failure(let failure):
            status = .failed(error: YandexSQIError.yandexSQIRequestError(parent: failure))
            return
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
