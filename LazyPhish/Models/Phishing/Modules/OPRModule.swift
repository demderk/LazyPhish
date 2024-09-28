//
//  OPRModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

class OPRModule: RequestModule {
    var dependences: [any RequestModule] = []
    var status: ModuleStatus = .planned
    var OPRInfo: OPRInfo?

    init() {

    }

    init(bulk: BulkOPRModule) {
        dependences.append(bulk)
    }

    func execute(remote: RemoteInfo) async {
        status = .executing
        if let bulkDependency = dependences.first(where: {$0 is BulkOPRModule}) as? BulkOPRModule {
            if let found = bulkDependency.cache?.first(where: {$0.domain == remote.url.strictHost}) {
                OPRInfo = found
            }
        } else {
            do {
                OPRInfo = try await singleBulkRequest(remote: remote)
            } catch let err as RequestError{
                status = .failed(error: err)
            } catch {
                status = .failed(error: OPRError.unknownError(underlyingError: error))
            }
        }
        status = .completed
    }

    private func singleBulkRequest(remote: RemoteInfo) async throws -> OPRInfo {
        let bulk = BulkOPRModule()
        _ = await bulk.execute(remote: remote)
        if case .failed(let error) = bulk.status {
            throw error
        }
        if let found = bulk.cache?.first(where: {$0.domain == remote.url.strictHost}) {
            return found
        }
        fatalError("pizda...")
    }
}
