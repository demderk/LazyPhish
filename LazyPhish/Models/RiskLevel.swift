//
//  RiskLevel.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation
import SwiftUI
enum RiskLevel: Int, Comparable, Codable {

    case common = 0
    case suspicious = 1
    case danger = 2

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
