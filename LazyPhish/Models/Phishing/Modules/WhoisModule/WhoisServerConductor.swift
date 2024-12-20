//
//  WhoisServerConductor.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 09.12.2024.
//

import os

enum ConductorError: Error {
    case waiterErrorBase
}

actor ServerWaiter {
    private(set) var base: WhoisServerInfo
    
    var server: String { base.server }
    var isBlinded: Bool  { base.isBlinded }
    var maxConnections: Int { base.maxConnections }
    
    private var avaliable: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(_ base: WhoisServerInfo) {
        self.base = base
        avaliable = base.maxConnections
    }
    
    func wait() async {
        
        avaliable -= 1
        if avaliable >= 0 { return }
        await withCheckedContinuation {
            waiters.append($0)
        }
    }
    // if signalCount > 0 then drop other
    func signal(_ count: Int = 1) {
        assert(count >= 1)
        for _ in 0..<count {
            if waiters.isEmpty { return }
            self.avaliable += 1
            waiters.removeFirst().resume()
        }
    }
    
    func updateBase(_ newBase: WhoisServerInfo) throws {
//        guard base == newBase else {
//            throw ConductorError.waiterErrorBase
//        }
        
        let currentMaxConnections = maxConnections
        let newMaxConnections = newBase.maxConnections
        let newThreadSlots = newMaxConnections - currentMaxConnections
        
        base = newBase
        if (newThreadSlots > 0) {
            avaliable = newThreadSlots
            signal(newThreadSlots)
        }
    }
    
//    static func ==(lhs: ServerWaiter, rhs: ServerWaiter) async -> Bool {
//        await lhs.tld == rhs.tld
//    }
}

class WaiterLink: Hashable {
    
    private(set) var waiter: ServerWaiter
    
    private(set) var tld: String
    
    init(tld: String, base: ServerWaiter) {
        self.waiter = base
        self.tld = tld
    }
    
    func updateWaiter(_ newBase: ServerWaiter) {
        waiter = newBase
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tld)
    }
    
    static func ==(lhs: WaiterLink, rhs: WaiterLink) -> Bool {
        lhs.tld == rhs.tld
    }
}

actor WhoisServerConductor {
    private let baseConnectionCount = 1
    
    let sessionCache = WhoisCache()
    private var waiters: Set<WaiterLink> = []
    
    func wait(_ host: String) async -> WhoisServerInfo {
        let tld = sessionCache.getTLD(host)
        if let found = waiters.first(where: { $0.tld == tld }) {
            await found.waiter.wait()
            return await found.waiter.base
        }
        let cached = sessionCache.pull(host)
        let waiter = ServerWaiter(cached)
        let link = WaiterLink(tld: tld, base: waiter)
        waiters.insert(link)
        await link.waiter.wait()
        return await link.waiter.base

    }
    
    func signal(_ host: String) async {
        let tld = sessionCache.getTLD(host)
        if let found = waiters.first(where: { $0.tld == tld }) {
            await found.waiter.signal()
            return
        }
        Logger.whoisRequestLogger.error("Signal was published but waiter is not found")
    }
    
    func updateCache(host: String, server: String) async {
        let pushInfo = sessionCache.push(host: host, server: server)
        
        guard pushInfo.inserted else { return }
        
        let newEntry = pushInfo.memberAfterInsert
        
        if let found = waiters.first(where: { $0.tld == newEntry.tld }) {
            try! await found.waiter.updateBase(newEntry)
        } else {
            let newWaiter = ServerWaiter(newEntry)
            waiters.insert(WaiterLink(tld: newEntry.tld, base: newWaiter))
        }
        
        
        
    }
}
