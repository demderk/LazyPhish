//
//  MLEntry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.03.2024.
//

import Foundation

struct MLEntry {
    var isIP: Bool
    var creationDate: RiskLevel
    var urlLength: RiskLevel
    var yandexSQI: Int
}
