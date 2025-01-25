//
//  BulkOPRModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

class BulkOPRModule: RequestModule {
    var dependences: DependencyCollection = DependencyCollection()
    var status: RemoteJobStatus = .planned

    var cache: [OPRInfo]?

    func cached(_ url: StrictURL) -> OPRInfo? {
        let formatedStrict = url.cleanHost
            .lowercased()
        let formatedRoot = url.hostRoot
            .lowercased()
        return cache?.first(where: {$0.domain == formatedStrict})
                ?? cache?.first(where: {$0.domain == formatedRoot})
    }

    func execute(remote: RemoteRequest) async {
        await bulk([remote.url])
    }
    
    func bulk(_ data: [StrictURL]) async {
        guard let apiKey = try? getOPRKey() else {
            status = .failed(OPRError.apiKeyUnreachable)
            return
        }

        var links: [[StrictURL]] = []

        if data.count > 100 {
            links = data.chunked(into: 100)
        } else {
            links.append(data)
        }

        status = .executing
        let infoArray = await withThrowingTaskGroup(
            of: (OPRResponse?).self,
            returning: [OPRInfo].self
        ) { tasks in
            for item in links {
                tasks.addTask { [self] in
                    return try await makeRESTRequest(data: item, apiKey: apiKey)
                }
            }
            var result: [OPRInfo] = []
            do {
                var anyFailed: Bool = false
                for try await part in tasks {
                    if let success = part {
                        for opr in success.response {
                            if let successInfo = opr as? OPRInfo {
                                result.append(successInfo)
                            }
                            if let failedInfo = opr as? FailedOPRInfo {
                                anyFailed = true
                                result.append(OPRInfo(failed: failedInfo))
                            }
                        }
                    }
                }
                if anyFailed {
                    status = .completedWithErrors()
                } else {
                    status = .completed
                }
            } catch let error as OPRError {
                Logger.OPRRequestLogger.error("[OPRProcess] \(error.localizedDescription)")
                status = .failed(error)
                return []
            } catch {
                Logger.OPRRequestLogger.critical("[OPRProcess] [unexpected] \(error)")
                status = .failed(OPRError.unknownError(underlyingError: error))
                return []
            }
            status = .completed
            return result
        }

        cache = infoArray
    }

    internal func getOPRKey() throws -> String {
        if !KeyService.inited {
            KeyService.refreshAllKeys()
        }
        if let opr = KeyService.OPRKey {
            return opr
        }
        throw OPRError.apiKeyUnreachable
    }

    func makeRESTRequest(data: [StrictURL], apiKey: String) async throws -> OPRResponse {
        var url = URLComponents(string: "https://openpagerank.com/api/v1.0/getPageRank")!

        var querryItems: [URLQueryItem] = []
        for (n, item) in data.enumerated() {
            querryItems.append(
                URLQueryItem(
                    name: "domains[\(n)]",
                    value: item.strictHost))
        }
        url.queryItems = querryItems

        let urlRequest = try URLRequest(
            url: url,
            method: .get,
            headers: ["API-OPR": apiKey])

        var remoteResponse: Data
        do {
            remoteResponse = try await URLSession.shared.data(for: urlRequest).0
        } catch {
            throw OPRError.requestError(underlyingError: error)
        }
        do {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            return try jsonDecoder.decode(OPRResponse.self, from: remoteResponse)
        } catch {
            throw OPRError.remoteError(response: String(data: remoteResponse, encoding: .utf8) ?? "")
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
