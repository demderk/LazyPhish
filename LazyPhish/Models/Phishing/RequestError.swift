//
//  RequestError.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation
import AppKit

protocol RemoteJobError: Error {
    var localizedDescription: String { get }
}

protocol ModuleError: RemoteJobError {
    
}

enum WhoisError: ModuleError {
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

enum ParserError: ModuleError {
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

enum OPRError: ModuleError {
    case unknownError(underlyingError: Error)
    case requestError(underlyingError: Error)
    case remoteError(response: String)
    case singleRequestCountExceeded
    case apiKeyUnreachable
    case pipelineFirstIsNull
    case creationDateNotParsed
    case failedToLink(url: String)

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
        case .creationDateNotParsed:
            "Creation date can't be parsed"
        case .failedToLink(let url):
            "Failed to link \(url)"
        }
    }
}

enum YandexSQIError: ModuleError {
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
