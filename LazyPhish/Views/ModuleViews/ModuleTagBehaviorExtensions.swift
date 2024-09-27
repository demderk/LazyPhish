//
//  ModuleTagBehaviorExtensions.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 26.09.2024.
//

import Foundation

extension WhoisModule: ModuleTagBehavior {

    var risk: RiskLevel {
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

    var tags: [ModuleTag] {
        let color = risk.getColor()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        var text = "Creation data unavailable"
        dateFormatter.locale = Locale(identifier: "en_US")
        if let date = self.whois?.creationDate {
            text = "Created: " + dateFormatter.string(from: date)
        }

        var result: [ModuleTag] = []
        if let whoisData = self.whois {
            if case .completed = self.status {
                result.append(ModuleTag(displayText: text, color: color))
            }
        }
        return result
    }
}

extension OPRModule: ModuleTagBehavior {
    var risk: RiskLevel {
        return OPRInfo == nil ? .danger : .common
    }

    var tags: [ModuleTag] {
        let text = self.OPRInfo == nil ? "OPR is empty" : "OPR Rank is \(OPRInfo?.rank ?? "%%")"
        return [ModuleTag(displayText: text, color: risk.getColor())]
    }
}

extension SQIModule: ModuleTagBehavior {
    var risk: RiskLevel {
        return self.yandexSQI == nil ? .danger : .common

    }

    var tags: [ModuleTag] {
        let text = self.yandexSQI == nil ? "Yandex SQI is empty" : "Yandex SQI is \(self.yandexSQI?.description ?? "%%")"
        return [ModuleTag(displayText: text, color: risk.getColor())]
    }
}

extension RegexModule: ModuleTagBehavior {
    private var prefixRisk: RiskLevel {
        if self.prefixCount > 1 {
            return .danger
        } else if self.prefixCount == 1 {
            return .suspicious
        } else {
            return.common
        }
    }

    private var subdomainRisk: RiskLevel {
        if self.subdomainCount > 1 {
            return .danger
        } else if self.prefixCount == 1 {
            return .suspicious
        } else {
            return.common
        }
    }

    private var lengthRisk: RiskLevel {
        if self.subdomainCount > 75 {
            return .danger
        } else if self.prefixCount < 54 {
            return .common
        } else if self.prefixCount <= 75 {
            return .suspicious
        }
        return .danger
    }

    private var ipRisk: RiskLevel {
        return isIP ? .danger : .common
    }

    var tags: [ModuleTag] {
        let prefixText = "URL have \(self.prefixCount.description) prefix"
        let prefixTag = ModuleTag(displayText: prefixText, color: prefixRisk.getColor())

        let subdomainsText = "URL have \(self.subdomainCount.description) subdomains"
        let subdomainsTag = ModuleTag(displayText: subdomainsText, color: subdomainRisk.getColor())

        let lengthText = "URL have \(self.urlLength) characters"
        let lengthTag = ModuleTag(displayText: lengthText, color: lengthRisk.getColor())

        let ipText = self.isIP ? "It's IP" : "It's Domain"
        let ipTag = ModuleTag(displayText: ipText, color: ipRisk.getColor())

        return [prefixTag, subdomainsTag, lengthTag, ipTag]
    }
}
