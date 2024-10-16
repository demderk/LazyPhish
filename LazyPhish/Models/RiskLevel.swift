//
//  RiskLevel.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation
import SwiftUI
enum RiskLevel: Int, Comparable, Codable {

    case unknown = -1
    case common = 0
    case suspicious = 1
    case danger = 2

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension RiskLevel {
    func getColor() -> Color {
        switch self {
        case .common:
            return Color.green.opacity(0.35)
        case .suspicious:
            return Color.yellow.opacity(0.40)
        case .danger:
            return Color.red.opacity(0.45)
        case .unknown:
            return Color.gray.opacity(0.3)
        }
    }
}
