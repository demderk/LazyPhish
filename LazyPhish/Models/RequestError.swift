//
//  RequestError.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation

enum RequestError: Error {
    case dateFormatError
    case yandexSQICaptchaError
    case yandexSQIUnderfined(response: String)
    case yandexSQIImageParseError
    case authorityAccessError
    case OPRError
    
    var localizedDescription: String {
        switch self {
        case .dateFormatError:
            "Whois date formatted incorectly."
        case .yandexSQICaptchaError:
            "Yandex SQI provider requires Captcha."
        case .yandexSQIUnderfined:
            "Yandex SQI underfined error."
        default:
            "..."
        }
    }
}
