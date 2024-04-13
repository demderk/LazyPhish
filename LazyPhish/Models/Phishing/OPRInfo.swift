//
//  OPRInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation

struct OPRInfo: Codable {
    var statusCode: Int
    var error: String
    var pageRankInteger: Int
    var pageRankDecimal: Decimal
    var rank: String?
    var domain: String
}

struct OPRResponse: Codable {
    var statusCode: Int
    var response: [OPRInfo]
    var lastUpdated: String
}
