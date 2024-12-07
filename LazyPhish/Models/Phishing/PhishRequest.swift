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
            return OPRModule()
        case .ml:
            return MLModule()
        }
    }
}

class PhishRequest {
    public func executeRequest(url: StrictURL, modules: [DetectTool]) async -> RemoteRequest {
        let remote = RemoteRequest(url: url)
        let bulkModule = BulkOPRModule()
        await bulkModule.bulk([url])
        await remote.addBroadcastModule(bulkModule)
        for mod in modules {
            remote.addModule(mod.getModule())
        }
        await remote.executeAll()
        return remote
    }
}
