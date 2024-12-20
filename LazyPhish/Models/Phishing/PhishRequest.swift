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
    
    @discardableResult
    public func executeRequest(url: StrictURL, modules: [any RequestModule]) async -> RemoteRequest {
        let remote = RemoteRequest(url: url)
        remote.addModule(contentsOf: modules)
        await remote.executeAll()
        return remote
    }
    
    @discardableResult
    public func executeRequest(url: StrictURL, modules: [DetectTool]) async -> RemoteRequest {
        var mods: [any RequestModule] = []
        for module in modules {
            mods.append(module.getModule())
        }
        return await executeRequest(url: url, modules: mods)
    }
}
