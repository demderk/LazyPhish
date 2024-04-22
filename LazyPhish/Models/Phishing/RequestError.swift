//
//  RequestError.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation
import AppKit

enum RequestError: Error {
    case requestIsEmpty
    case dateFormatError
    case ipCheckRegexError
    case yandexSQICroppingError
    case yandexSQIVisionNotRecognizedUnknown
    case yandexSQIVisionPerformError(_ underlyingError: Error)
    case yandexSQIVisionNotRecognized(image: NSImage)
    case yandexSQIRequestError(parent: Error)
    case authorityAccessError
    case OPRUnknownError(underlyingError: Error)
    case OPRRequestError(underlyingError: Error)
    case OPRRemoteError(response: String)
    case OPRSingleRequestCountExceeded
    case OPRApiKeyUnreachable
    case unknownError(parent: Error)
    case urlHostIsInvalid(url: String)
    case urlNotAWebRequest(url: String)
    case urlHostIsBroken(url: String)
    case whoisIsNil
    case whoisUnknownError(underlyingError: Error)
    
    var localizedDescription: String {
        switch self {
        case .dateFormatError:
            "Whois date formatted incorectly."
        case .yandexSQIVisionNotRecognizedUnknown:
            "Unknown error. Yandex SQI Vision OCR did not recognized anything."
        case .yandexSQIVisionNotRecognized:
            "Yandex SQI Vision OCR did not recognized anything."
        case .yandexSQIRequestError(let parent):
            "Yandex SQI request error. Parent \(parent)."
        case .urlHostIsInvalid(let url):
            "Yandex SQI underfined error. \(url)"
        case .unknownError(let parent):
            "Unknown error \(parent)"
        case .urlNotAWebRequest(url: let url):
            "URL have not http:// or https:// component. URL: \(url)."
        case .ipCheckRegexError:
            "IP Regex Error."
        case .yandexSQICroppingError:
            "Yandex SQI Cropping Error."
        case .yandexSQIVisionPerformError:
            "Yandex SQI Vision Error."
        case .authorityAccessError:
            "Authority is inaccessible."
        case .OPRUnknownError(underlyingError: let underlyingError):
            "OPR unknown error. Underlying: \(underlyingError)."
        case .OPRRequestError(underlyingError: let underlyingError):
            "OPR Request error. Underlying: \(underlyingError)."
        case .OPRSingleRequestCountExceeded:
            "OPR request has over 100 objects."
        case .OPRApiKeyUnreachable:
            "Authority is unreachable."
        case .urlHostIsBroken(url: let url):
            "URL invalid host. URL:\(url)."
        case .whoisIsNil:
            "Whois returns Nil."
        case .whoisUnknownError(underlyingError: let underlyingError):
            "Whois unknown error. Underlying: \(underlyingError)."
        case .OPRRemoteError(response: let response):
            "OPR Provider throws an error. \(response)"
        case .requestIsEmpty:
            "Request is empty"
        }
    }
}
