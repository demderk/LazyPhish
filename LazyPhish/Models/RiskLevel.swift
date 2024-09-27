//
//  RiskLevel.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation
import SwiftUI
enum RiskLevel: Int, Comparable, Codable {

    case common = -1
    case suspicious = 0
    case danger = 1

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
