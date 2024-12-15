//
//  WhoisServerInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 09.12.2024.
//

import Foundation

struct WhoisServerInfo: Hashable {
    var tld: String
    var server: String
    var maxConnections: Int = 1000
    var isBlinded: Bool = false
    
    static let `default` = WhoisServerInfo(tld: "default", server: "whois.iana.org", maxConnections: 1)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tld)
    }
    
    static func ==(lhs: WhoisServerInfo, rhs: WhoisServerInfo) -> Bool {
        lhs.tld == rhs.tld
    }
}

extension WhoisServerInfo {
    init(name: String, blinded: Bool) {
        assert(blinded)
        isBlinded = blinded
        self.tld = name
        server = ""
    }
}
