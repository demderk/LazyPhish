//
//  File.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import SwiftUI

struct ModuleTag {
    var displayText: String
    var risk: RiskLevel
    var tagPriority: Int = 0
}

extension ModuleTag {
    var color: Color { risk.getColor() }
}
