//
//  OPRInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation

struct OPRInfo: Codable {
    var status_code: Int
    var error: String
    var page_rank_integer: Int
    var page_rank_decimal: Decimal
    var rank: String?
    var domain: String
}

struct OPRResponse: Codable {
    var status_code: Int
    var response: [OPRInfo]
    var last_updated: String
}
