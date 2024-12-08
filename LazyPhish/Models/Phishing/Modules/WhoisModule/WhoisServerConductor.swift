//
//  WhoisServerConductor.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 09.12.2024.
//

import os

actor WhoisServerConductor {
    private let baseConnectionCount = 1
    
    private var servers: [String: Semaphore] = [:]
        
    init() {
        servers["whois.iana.org"] = Semaphore(count: 1)
        for server in WhoisCache.staticStorage {
            servers[server.server] = Semaphore(count: server.maxConnections)
        }
    }
    
    func serverWait(_ host: String) async {
        if let server = servers[host] {
            await server.wait()
        } else {
            servers[host] = Semaphore(count: baseConnectionCount)
            await servers[host]!.wait()
        }
    }
    
    func serverSignal(_ host: String) async {
        if let server = servers[host] {
            await server.signal()
            return
        }
        Logger.whoisRequestLogger.error("Conductor signal without found semaphore. By host: \(host)")
    }
}
