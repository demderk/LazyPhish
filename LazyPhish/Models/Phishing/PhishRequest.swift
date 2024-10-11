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

enum DetectTool {
    case sqi
    case whois
    case regex
    case opr
    case ml

    func getModule() -> RequestModule {
        switch self {
        case .sqi:
            return SQIModule()
        case .whois:
            return WhoisModule()
        case .regex:
            return RegexModule()
        case .opr:
            var oprModule = OPRModule()
//            oprModule.dependences.pushDependencyInsecure(BulkOPRModule())
            return oprModule
        case .ml:
            return MLModule()
        }
    }
}

class NeoPhishRequest {
    public func executeRequest(url: StrictURL, modules: [DetectTool]) async -> RequestInfo {
        let remote = RequestInfo(url: url)
        for mod in modules {
            remote.addModule(mod.getModule())
        }
        await remote.executeAll()
        return remote
    }
}
