//
//  PhishML.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 14.05.2024.
//

import Foundation

import CoreML
import OSLog

extension RiskLevel {
    var raw64: Int64 {
        return Int64(self.rawValue)
    }
}
