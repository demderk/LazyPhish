//
//  File.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import SwiftUI

struct ModuleTagCard {
    var displayText: String
    var color: Color
}

protocol ModuleTagBehavior {
    var tags: [ModuleTagCard] { get }
}

extension WhoisModule: ModuleTagBehavior {
    
    private func calculateRisk() -> RiskLevel {
        if let whois = whois {
            if let date = whois.creationDate {
                if date.distance(to: .now) <= 60*60*24*180 {
                    return .danger
                } else if date.distance(to: .now) <= 60*60*24*365 {
                    return .suspicious
                } else {
                    return .common
                }
            }
        }
        return .danger
    }
    
    var tags: [ModuleTagCard] {
        let color = calculateRisk().getColor()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        var text = "Creation data unavailable"
        dateFormatter.locale = Locale(identifier: "en_US")
        if let date = self.whois?.creationDate {
            text = "Created: " + dateFormatter.string(from: date)
        }
        
        var result: [ModuleTagCard] = []
        if let whoisData = self.whois {
            if case .completed = self.status {
                result.append(ModuleTagCard(displayText: text, color: color))
            }
        }
        return result
    }
}
