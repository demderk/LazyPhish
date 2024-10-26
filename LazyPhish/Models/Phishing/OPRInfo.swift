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

enum OPRExternalError: Int, Error {
    case unknown = -1
    case notFound = 404
    case incorrectDomain = 400

    init(_ errorCode: Int) {
        if let found = OPRExternalError(rawValue: errorCode) {
            self = found
        } else {
            self = .unknown
        }
    }
}

struct OPRInfo: OPRFailable {
    var statusCode: Int
    var error: String
    var pageRankInteger: Int
    var pageRankDecimal: Decimal
    var rank: String?
    var domain: String
    var notFound: Bool { statusCode == 404 }
    var externalError: OPRExternalError? { OPRExternalError(statusCode) }
}

extension OPRInfo {
    init(failed: FailedOPRInfo) {
        statusCode = failed.statusCode
        error = failed.statusCode.description
        pageRankInteger = -1
        pageRankDecimal = -1
        domain = failed.domain
    }
}

struct OPRResponse: Decodable {
    var statusCode: Int
    @ThrowingOPRInfoList var response: [OPRFailable]
    var lastUpdated: String
}
