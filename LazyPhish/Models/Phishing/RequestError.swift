//
//  RequestError.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation
import AppKit

enum RequestError: Error {
    case dateFormatError
    case yandexSQICroppingError
    case yandexSQIVisionNotRecognizedUnknown
    case yandexSQIVisionNotRecognized(image: NSImage)
    case yandexSQIRequestError(parent: Error)
    case authorityAccessError
    case OPRError
    case unknownError(parent: Error)
    case concatCollision
    case urlHostIsInvalid(url: URL)
    
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
        default:
            "..."
        }
    }
}
