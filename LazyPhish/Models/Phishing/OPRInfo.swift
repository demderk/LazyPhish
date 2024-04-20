//
//  OPRInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation

protocol OPRFailable: Decodable {
    var statusCode: Int { get set }
    var error: String { get set}
    var domain: String { get set }
}

struct FailedOPRInfo: OPRFailable {
    var statusCode: Int
    var error: String
    var domain: String
}

struct OPRInfo: OPRFailable {
    var statusCode: Int
    var error: String
    var pageRankInteger: Int
    var pageRankDecimal: Decimal
    var rank: String?
    var domain: String
}

struct OPRResponse: Decodable {
    var statusCode: Int
    @ThrowingOPRInfoList var response: [OPRFailable]
    var lastUpdated: String
}
