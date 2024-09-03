//
//  VirusTotalPipeline.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 02.09.2024.
//

import Foundation
import Alamofire

protocol ModuleBehavior {
    associatedtype ErrorType: ModuleError
    var error: ErrorType? {get}
    var success: Bool {get}
}

protocol ModuleError: Error {
    
}

enum VirusTotalModuleError: ModuleError {
    case urlIsEmpty
    case requestError
    case parseError
}

class VirusTotalModule: ModuleBehavior {
    var error: VirusTotalModuleError?
    var success: Bool = false
    var reports: [AVReport]? = []
    var summary: [AVState: Int]?
    
    init(reports: [AVReport], summary: [AVState: Int]) {
        self.reports = reports
        self.success = true
        self.summary = summary
    }
    
    init(error: VirusTotalModuleError) {
        self.error = error
        success = false
    }
}

struct AVReport: Codable {
    var method: String
    var engineName: String
    var category: String
    var result: String
    
    enum CodingKeys: String, CodingKey {
        case engineName = "engine_name"
        case method = "method"
        case category = "category"
        case result = "result"
    }
}

enum AVState: String, Codable {
    case malicious
    case suspicious
    case undetected
    case harmless
    case timeout
}

class VirusTotalPipeline: PhishingPipelineObject {
    struct VirusTotalLinks: Codable {
        var resultLink: String
        
        enum CodingKeys: String, CodingKey {
            case resultLink = "self"
        }
    }

    struct VirusTotalIDResponse: Codable {
        var data: VirusTotalID
    }

    struct VirusTotalAVResponse: Codable {
        var data: VirusTotalAVData
    }

    struct VirusTotalAVData: Codable {
        var id: String
        var links: VirusTotalLinks
        var attributes: VirusTotalAnalysis
    }
    
    struct VirusTotalAnalysis: Codable {
        var results: [String: AVReport]
        var date: Int
        var status: String
        var stats: [String: Int]
        
        func linkedStats() -> [AVState: Int] {
            var result: [AVState: Int] = [:]
            for item in stats {
                if let state = AVState(rawValue: item.key) {
                    result[state] = item.value
                }
            }
            return result
        }
    }

    struct VirusTotalID: Codable {
        var id: String
        var links: VirusTotalLinks
    }
    
    func execute(data: any StrictRemote) async -> any StrictRemote {
        var tempData = data
        do {
            let virusTotalID = try await getVirusTotalID(url: data.host)
            let virusTotalAnalysis = try await getVirusTotalAnalysis(id: virusTotalID)
            tempData.modules.append(VirusTotalModule(reports: Array(virusTotalAnalysis.results.values), summary: virusTotalAnalysis.linkedStats()))
            print(VirusTotalModule(reports: Array(virusTotalAnalysis.results.values), summary: virusTotalAnalysis.linkedStats()))
        } catch let error as VirusTotalModuleError {
            tempData.modules.append(VirusTotalModule(error: error))
            print(error)
        } catch {
            print(error)
        }
        return tempData
    }
    
    func getVirusTotalID(url: String) async throws -> VirusTotalID {
        guard let apiKey = KeyService.VTKey else {
            throw VirusTotalModuleError.urlIsEmpty
        }
        
        let headers: HTTPHeaders = ["x-apikey": apiKey]
        
        let ur = try! URLRequest(
            url: "https://www.virustotal.com/api/v3/urls?url=\(url)",
            method: .post,
            headers: ["x-apikey": apiKey])
        
        var data: Data
        
        do {
            data = try await URLSession.shared.data(for: ur).0
            print(String(decoding: data, as: UTF8.self))
        } catch {
            throw VirusTotalModuleError.requestError
        }
        do {
            return try JSONDecoder().decode(VirusTotalIDResponse.self, from: data).data
        } catch {
            throw VirusTotalModuleError.parseError
        }
    }
    
    func getVirusTotalAnalysis(id: VirusTotalID) async throws -> VirusTotalAnalysis {
        guard let apiKey = KeyService.VTKey else {
            throw VirusTotalModuleError.urlIsEmpty
        }
        
        let headers: HTTPHeaders = ["x-apikey": apiKey]
        
        let ur = try! URLRequest(
            url: "https://www.virustotal.com/api/v3/analyses/\(id.id)",
            method: .get,
            headers: ["x-apikey": apiKey])
        
        var data: Data
        
        do {
            data = try await URLSession.shared.data(for: ur).0
            print(String(decoding: data, as: UTF8.self))
        } catch {
            throw VirusTotalModuleError.requestError
        }
        do {
            return try JSONDecoder().decode(VirusTotalAVResponse.self, from: data).data.attributes
        } catch {
            throw VirusTotalModuleError.parseError
        }
    }
}
