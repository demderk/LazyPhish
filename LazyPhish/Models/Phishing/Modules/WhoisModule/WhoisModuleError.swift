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
    
    var localizedDescription: String {
        switch self {
        case .timeout:
            "Whois timed out."
        case .unknown(let underlying):
            "Whois unknown error. Underlying Error: \(underlying)"
        case .NIOInternal(let underlying):
            "SwiftNIO internal error. Underlying Error: \(underlying)"
        case .emptyData:
            "Whois server returns empty data."
        case .dateParserError:
            "The date was not parsed. The whois database may not contain this information."
        }
    }
}
