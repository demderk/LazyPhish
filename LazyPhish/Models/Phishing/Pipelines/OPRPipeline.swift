////
////  OPRPipeline.swift
////  LazyPhish
////
////  Created by Roman Zheglov on 28.08.2024.
////
//
//import Foundation
//import OSLog
//import Alamofire
//
//class OPRPipeline: PhishingArrayPipelineObject {
//    func execute(data: any StrictRemote) async -> any StrictRemote {
//        Logger.OPRRequestLogger.warning("Error")
//        if let first = await executeAll(data: [data]).first {
//            return first
//        }
//        var err = data
//        err.remote.OPR = .failed(error: OPRError.pipelineFirstIsNull)
//        Logger.OPRRequestLogger.error("Pipeline execute method failed (First is null)")
//        return err
//    }
//    
//    // TODO: Array надо на Set заменить. Мы не знаем порядок элементов
//    // В singleOPRRequest тоже порядок может меняться. Лучше контроллировать этот процесс
//    func executeAll(data remoteObjects: [any StrictRemote]) async -> [any StrictRemote] {
//        if remoteObjects.count < 100 {
//            return await singleOPRRequest(remoteObjects: remoteObjects)
//        }
//        let splitedRemote = remoteObjects.chunked(into: 100)
//        
//        let finalRemote = await withTaskGroup(
//            of: [StrictRemote].self,
//            returning: [StrictRemote].self
//        ) { requestPool in
//            for item in splitedRemote {
//                // TODO: Weak Self?
//                requestPool.addTask { [self] in
//                    await singleOPRRequest(remoteObjects: item)
//                }
//            }
//            var result: [StrictRemote] = []
//            for await request in requestPool {
//                result.append(contentsOf: request)
//            }
//            return result
//        }
//        return finalRemote
//    }
//    
//    internal func getOPRKey() throws -> String {
//        if !KeyService.inited {
//            KeyService.refreshAllKeys()
//        }
//        if let opr = KeyService.OPRKey {
//            return opr
//        }
//        throw RequestCriticalError.authorityAccessError
//    }
//    
//    func singleOPRRequest(remoteObjects: [StrictRemote]) async -> [StrictRemote] {
//        var result: [StrictRemote] = []
//        guard remoteObjects.count <= 100 else {
//            for item in remoteObjects {
//                var temp = item
//                temp.remote.OPR = .failed(error: OPRError.singleRequestCountExceeded)
//                result.append(temp)
//            }
//            return result
//        }
//        guard let apiKey = try? getOPRKey() else {
//            for item in remoteObjects {
//                var temp = item
//                temp.remote.OPR = .failed(error: OPRError.apiKeyUnreachable)
//                result.append(temp)
//            }
//            return result
//        }
//        var params: [String: String] = [:]
//        for (n, item) in remoteObjects.enumerated() {
//            params["domains[\(n)]"] = item.host
//        }
//        let headers: HTTPHeaders = [ "API-OPR": apiKey ]
//        let jsonDecoder = JSONDecoder()
//        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
//        
//        let request = AF.request(
//            "https://openpagerank.com/api/v1.0/getPageRank",
//            parameters: params,
//            headers: headers
//        )
//        
//        let afResult = request.serializingDecodable(OPRResponse.self, decoder: jsonDecoder)
//        
//        switch await afResult.result {
//        case .success(let success):
//            let response = success.response
//            
//            for item in response {
//                guard var found = remoteObjects.first(
//                    where: {
//                        $0.host.lowercased() == item.domain.lowercased() ||
//                        $0.host.lowercased() == "www.\(item.domain.lowercased())" }
//                ) else {
//                    fatalError(item.domain)
//                }
//                if let successResult = item as? OPRInfo {
//                    found.remote.OPR = .success(value: successResult)
//                    result.append(found)
//                } else {
//                    found.remote.OPR = .failed(
//                        error: OPRError.remoteError(response: "[\(item.statusCode)] \(item.error)"))
//                    result.append(found)
//                }
//            }
//            return result
//        case .failure(let error):
//            for item in remoteObjects {
//                var temp = item
//                temp.remote.OPR = .failed(error: OPRError.requestError(underlyingError: error))
//                result.append(temp)
//            }
//            return result
//        }
//    }
//}
