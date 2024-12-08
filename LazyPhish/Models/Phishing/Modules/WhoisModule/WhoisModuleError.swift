//
//  WhoisModuleError.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.12.2024.
//


enum WhoisModuleError: ModuleError {
    case emptyData
    case dateParserError
    case timeout
    case NIOInternal(_ underlyingError: Error)
    case unknown(_ underlyingError: Error)
}

//enum WhoisError: ModuleError {
//    case responseIsNil
//    case badRequest(description: String)
//    case badResponse
//    case timeout
//    case dateFormatError
//    case unknown(_ underlying: Error)
//
//    var isCritical: Bool {
//        switch self {
//        case .dateFormatError:
//            false
//        default:
//            true
//        }
//    }
//
//    var localizedDescription: String {
//        switch self {
//        case .responseIsNil:
//            "WHOIS Response is nil."
//        case .badResponse:
//            "WHOIS bad response."
//        case .timeout:
//            "WHOIS timeout."
//        case .dateFormatError:
//            "WHOIS date formatted incorectly."
//        case .unknown(let underlying):
//            "WHOIS Unknown Error. Underlying Error: \(underlying)"
//        case .badRequest(description: let description):
//            "Bad WHOIS Request. \(description)"
//        }
//    }
//}
