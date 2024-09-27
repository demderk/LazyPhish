////
////  NeoPhishInfo.swift
////  LazyPhish
////
////  Created by Roman Zheglov on 03.09.2024.
////
//
// import Foundation
// import OSLog
//
// struct StrictURL {
//    var URL: URL
//
//    var strictHost: String {
//        URL.host()!
//    }
//
//    init(url: String) throws {
//        URL = try PhishInfoFormatter.validURL(url)
//    }
//
//    init(url: String, preActions: Set<FormatPreaction>) throws {
//        URL = try PhishInfoFormatter.validURL(url, preActions: preActions)
//    }
// }
//
/// * Modules:
// OPRModule
// SQIModule
// WhoisModule
// VisualModule
// AIModule
//
// Модули могут требовать зависимости.
// */
//
//// class NeoPhishInfo {
////    var url: StrictURL
////    var modules: [PhishModule]
//// }
//
// class RequestPipeline {
//    var modules: [PhishModule] = []
//    private var cachedModules: [PhishModule] = []
//    private var queue: OperationQueue = OperationQueue()
//
//    func start() {
//        var opro = processPipe(phishModule: OPRModule())
//
//    }
//
//    func processPipe(phishModule: PhishModule) -> PhishModule {
//
//    }
// }
//
// enum ModuleStatus {
//    case planned
//    case excalated
//    case failed(error: RequestError)
//    case canceled
//    case finished
// }
//
// protocol PhishModule {
//    var status: ModuleStatus { get set}
//    var dependences: [any PhishModule] { get set }
//    var operation: Operation! { get }
//    var refreshDependences: Bool {get}
//    var cacheable: Bool {get}
//    func validateDeps(_ phishModule: PhishModule) -> Bool
// }
//
// class NeoPhishRequest {
//
// }
//
//
// class OPRModule: PhishModule {
//    var status: ModuleStatus = .planned
//    var dependences: [any PhishModule] = []
//    var operation: Operation!
//    var refreshDependences: Bool = false
//    var cacheable: Bool = true
//    var response: [OPRInfo]?
//
//    private var executedArray: [OPRInfo]? {
//        guard let executed = operation as? OPROperation else {
//            return nil
//        }
//        return executed.result
//    }
//
//    func validateDeps(_ phishModule: any PhishModule) -> Bool {
//        true
//    }
//
//    init() {
//        operation = OPROperation(parent: self)
//    }
//
//    func getOPRInfo(phishInfo: StrictURL) -> OPRInfo {
//        return (executedArray?.first(where: {$0.domain == phishInfo.strictHost}))!
//    }
// }
//
// class OPROperation: AsyncOperation {
//
//    weak var parentModule: OPRModule?
//    var toExecute: [StrictURL] = []
//    var result: [OPRInfo]?
//    var isFailed: Bool = false
//    var error: OPRError?
//
//    init(parent: OPRModule) {
//        parentModule = parent
//    }
//
//    override func start() {
//
//        guard let apiKey = try? getOPRKey() else {
//            fail(OPRError.apiKeyUnreachable)
//            return
//        }
//
//        var OPRItems: [[StrictURL]] = []
//
//        if toExecute.count > 100 {
//            OPRItems = toExecute.chunked(into: 100)
//        } else {
//            OPRItems.append(toExecute)
//        }
//
//        Task { [OPRItems] in
//            isExecuting = true
//            var result: [OPRResponse] = []
//            do {
//                for item in OPRItems {
//                    guard !isCancelled else {
//                        return
//                    }
//                    result.append(try await makeRESTRequest(data: item, apiKey: apiKey))
//                }
//            } catch let error as OPRError {
//                fail(error)
//                Logger.OPRRequestLogger.error("[OPRProcess] \(error.localizedDescription)")
//                isExecuting = false
//                isFinished = true
//                return
//            } catch {
//                Logger.OPRRequestLogger.critical("[OPRProcess] [unexpected] \(error)")
//                return
//            }
//            self.result = result.flatMap({($0.response).map({$0 as! OPRInfo})})
//            parentModule?.response = self.result
//            isExecuting = false
//            isFinished = true
//
//        }
//    }
//
//    private func fail(_ error: OPRError) {
//        isFailed = true
//        self.error = error
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
//    func makeRESTRequest(data: [StrictURL], apiKey: String) async throws -> OPRResponse {
//        var url = URLComponents(string: "https://openpagerank.com/api/v1.0/getPageRank")!
//
//        var querryItems: [URLQueryItem] = []
//        for (n, item) in data.enumerated() {
//            querryItems.append(
//                URLQueryItem(
//                    name: "domains[\(n)]",
//                    value: item.strictHost))
//        }
//        url.queryItems = querryItems
//
//        let urlRequest = try URLRequest(
//            url: url,
//            method: .get,
//            headers: ["API-OPR": apiKey])
//
//        var remoteResponse: Data
//        do {
//            remoteResponse = try await URLSession.shared.data(for: urlRequest).0
//        } catch {
//            throw OPRError.requestError(underlyingError: error)
//        }
//        do {
//            let jsonDecoder = JSONDecoder()
//            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
//            return try jsonDecoder.decode(OPRResponse.self, from: remoteResponse)
//        } catch {
//            throw OPRError.remoteError(response: String(decoding: remoteResponse, as: UTF8.self))
//        }
//    }
// }

import Foundation
import OSLog
