//
//  StrictURL.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

struct StrictURL {
    
    // There are
    // static let twoSLDs: [String]
    
    var URL: URL
    
    var strictHost: String {
        URL.host()!
    }
    
    var hostRoot: String {
        return StrictURL.getTLD(host: strictHost) ?? strictHost
    }
    
    var isTwoSLD: Bool {
        return StrictURL.isTwoSLD(host: strictHost)
    }
    
    init(url: String) throws {
        URL = try PhishInfoFormatter.validURL(url)
    }

    init(url: String, preActions: Set<FormatPreaction>) throws {
        URL = try PhishInfoFormatter.validURL(url, preActions: preActions)
    }
}
