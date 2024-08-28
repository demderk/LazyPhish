//
//  RequestError.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation
import AppKit

protocol RequestError: Error {
    var isCritical: Bool {get}
    var localizedDescription: String { get }
}

extension RequestError {
    var isCritical: Bool { true }
}

enum WhoisError: RequestError {
    case responseIsNil
    case badRequest(description: String)
    case badResponse
    case timeout
    case dateFormatError
    case unknown(_ underlying: Error)
    
    var isCritical: Bool {
        switch self {
        case .dateFormatError:
            false
        default:
            true
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .responseIsNil:
            "WHOIS Response is nil."
        case .badResponse:
            "WHOIS bad response."
        case .timeout:
            "WHOIS timeout."
        case .dateFormatError:
            "WHOIS date formatted incorectly."
        case .unknown(let underlying):
            "WHOIS Unknown Error. Underlying Error: \(underlying)"
        case .badRequest(description: let description):
            "Bad WHOIS Request. \(description)"
        }
    }
}

enum ParserError: RequestError {
    case requestIsEmpty
    case ipCheckRegexError
    case urlHostIsInvalid(url: String)
    case urlNotAWebRequest(url: String)
    case urlHostIsBroken(url: String)
        
    var localizedDescription: String {
        switch self {
        case .urlNotAWebRequest(url: let url):
            "URL have not http:// or https:// component. URL: \(url)."
        case .ipCheckRegexError:
            "IP Regex Error."
        case .urlHostIsBroken(url: let url):
            "URL invalid host. URL:\(url)."
        case .requestIsEmpty:
            "Request is empty"
        case .urlHostIsInvalid(let url):
            "URL Swift Parse Error. \(url)"
        }
    }
}

enum OPRError: RequestError {
    case unknownError(underlyingError: Error)
    case requestError(underlyingError: Error)
    case remoteError(response: String)
    case singleRequestCountExceeded
    case apiKeyUnreachable
    case pipelineFirstIsNull
        
    var localizedDescription: String {
        switch self {
        case .unknownError(underlyingError: let underlyingError):
            "OPR unknown error. Underlying: \(underlyingError)."
        case .singleRequestCountExceeded:
            "OPR request has over 100 objects."
        case .remoteError(response: let response):
            "OPR Provider throws an error. \(response)"
        case .apiKeyUnreachable:
            "OPR auth key is inaccessible."
        case .requestError:
            "OPR HTTPS Request error."
        case .pipelineFirstIsNull:
            "Pipeline execute method failed"
        }
    }
}

enum YandexSQIError: RequestError {
    case yandexSQICroppingError
    case yandexSQIVisionNotRecognizedUnknown
    case yandexSQIVisionPerformError(_ underlyingError: Error)
    case yandexSQIVisionNotRecognized(image: NSImage)
    case yandexSQIRequestError(parent: Error)
    
    var isCritical: Bool {
        switch self {
        case .yandexSQIVisionNotRecognized:
            false
        default:
            true
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .yandexSQIVisionNotRecognized:
            "Yandex SQI Vision OCR did not recognized anything."
        case .yandexSQIRequestError(let parent):
            "Yandex SQI request error. Parent \(parent)."
        case .yandexSQIVisionNotRecognizedUnknown:
            "Unknown error. Yandex SQI Vision OCR did not recognized anything."
        case .yandexSQICroppingError:
            "Yandex SQI Cropping Error."
        case .yandexSQIVisionPerformError:
            "Yandex SQI Vision Error."
        }
    }
}

enum FileError: RequestError {
    case nothingToExport
        
    var localizedDescription: String {
        switch self {
        case .nothingToExport:
            "Export data is empty."
        }
    }
}

enum RequestCriticalError: RequestError {
    case authorityAccessError
    case unknownUnderlyingError(underlying: Error)
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .authorityAccessError:
            "Authority is inaccessible."
        case .unknownUnderlyingError(let underlying):
            "Unknown error. Underlying error: \(underlying)"
        case .unknownError:
            "Unknown error."
        }
    }
}
