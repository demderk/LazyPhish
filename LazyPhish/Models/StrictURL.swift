//
//  StrictURL.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

struct StrictURL {
    var URL: URL

    var strictHost: String {
        URL.host()!
    }

    init(url: String) throws {
        URL = try PhishInfoFormatter.validURL(url)
    }

    init(url: String, preActions: Set<FormatPreaction>) throws {
        URL = try PhishInfoFormatter.validURL(url, preActions: preActions)
    }
}
