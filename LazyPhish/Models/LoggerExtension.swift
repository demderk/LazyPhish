//
//  LoggerExtension.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 06.06.2024.
//

import Foundation
import OSLog

extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier!
    static let whoisRequestLogger = Logger(
        subsystem: subsystem,
        category: "Whois Request")
    
    static let yandexSQIRequestLogger = Logger(
        subsystem: subsystem,
        category: "Yandex SQI Request")
    
    static let OPRRequestLogger = Logger(
        subsystem: subsystem,
        category: "OPR Request")
    
    static let MLModelLogger = Logger(
        subsystem: subsystem,
        category: "ML Model")
}
