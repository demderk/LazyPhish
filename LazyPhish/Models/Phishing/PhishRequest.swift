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
        await refreshRemoteData(base, collectMetrics: [YandexSQIPipeline(),
                                                       OPRPipeline(),
                                                       WhoisPipeline()])
    }
        
    public func refreshRemoteData(_ base: StrictRemote,
                                  collectMetrics: [PhishingPipelineObject]
    ) async -> PhishInfo {
        
        let remote = await withTaskGroup(of: StrictRemote.self,
                                         returning: StrictRemote.self
        ) { taskGroup in
            
                var result: StrictRemote = base
                for item in collectMetrics {
                    taskGroup.addTask { [self] in
                        await item.execute(data: base)
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
