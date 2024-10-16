//
//  OPRModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

class OPRModule: RequestModule {
    var dependences: DependencyCollection = DependencyCollection([
        BulkOPRModule()
    ])
    var status: ModuleStatus = .planned
    var OPRInfo: OPRInfo?
    var rank: Int? {
        if let rank = OPRInfo?.rank {
            return Int(rank)
        } else {
            return nil
        }
    }
    
    init() {
        
    }
    
    init(bulk: BulkOPRModule) {
        dependences.pushDependencyInsecure(bulk)
    }
    
    func execute(remote: RequestInfo) async {
        status = .executing
        if let bulkDependency = await dependences.getDependency(module: BulkOPRModule()) as? BulkOPRModule,
           let found = bulkDependency.cached(remote.url) {
            if case .failed(let error) = bulkDependency.status {
                status = .failed(error: error)
                return
            } else {
                OPRInfo = found
                status = .completed
                return
            }
            
        } else {
            do {
                OPRInfo = try await singleBulkRequest(remote: remote)
                status = .completed
                return
            } catch let err as RequestError {
                status = .failed(error: err)
                return
            } catch {
                status = .failed(error: OPRError.unknownError(underlyingError: error))
                return
            }
        }
    }
    
    private func singleBulkRequest(remote: RequestInfo) async throws -> OPRInfo {
        let bulk = BulkOPRModule()
        _ = await bulk.execute(remote: remote)
        if case .failed(let error) = bulk.status {
            throw error
        }
        if let found = bulk.cached(remote.url) {
            return found
        }
        Logger.OPRRequestLogger.error("\(remote.hostRoot) was not linked.")
        throw OPRError.failedToLink(url: remote.hostRoot)
    }
}
