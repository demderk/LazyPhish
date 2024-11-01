//
//  ModuleTagBehaviorExtensions.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 26.09.2024.
//

import Foundation

extension WhoisModule: ModuleTagBehavior {
    var dateRisk: RiskLevel {
        if let whois = whois {
            if blinded {
                return .unknown
            }
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
    var foundRisk: RiskLevel {
        return whoisFound ? .common : .danger
    }

    var tags: [ModuleTag] {
        var result: [ModuleTag] = []
        let foundText = whoisFound ? "Whois is found" : "Whois not found"
        result.append(ModuleTag(
            displayText: dateText,
            risk: dateRisk,
            tagPriority: modulePriority.rawWithTag(tagPriotiry: 0)))
        result.append(ModuleTag(
            displayText: foundText,
            risk: foundRisk,
            tagPriority: 0))
        return result
    }
}

extension OPRModule: ModuleTagBehavior {
    var priority: Int { 2 }

    var risk: RiskLevel {
        return OPRInfo?.rank == nil ? .danger : .common
    }

    var tags: [ModuleTag] {
        var text = "OPR failed"
        if let opr = self.OPRInfo {
            if opr.notFound {
                text = "OPR not found"
            } else {
                text = self.OPRInfo?.rank == nil ? "OPR failed" : "OPR Rank is \(OPRInfo?.rank ?? "%%")"
            }
        }
        return [
            ModuleTag(
            displayText: text,
            risk: risk,
            tagPriority: modulePriority.rawWithTag(tagPriotiry: 0))
        ]
    }
}

extension SQIModule: ModuleTagBehavior {
    private var yandexSQIMinimum: Int { 0 }

    var priority: Int { 1 }

    var risk: RiskLevel {
        if let sqi = yandexSQI {
            if sqi > yandexSQIMinimum {
                return .common
            } else {
                return .danger
            }
        } else {
            return .danger
        }

    }

    var tags: [ModuleTag] {
        let text = self.yandexSQI == nil
        ? "Yandex SQI is empty"
        : "Yandex SQI is \(self.yandexSQI?.description ?? "%%")"
        return [
            ModuleTag(
                displayText: text,
                risk: risk,
                tagPriority: modulePriority.rawWithTag(tagPriotiry: 0))]
    }
}

extension RegexModule: ModuleTagBehavior {
    var priority: Int { 0 }
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
        let prefixTag = ModuleTag(
            displayText: prefixText,
            risk: prefixRisk,
            tagPriority: modulePriority.rawWithTag(tagPriotiry: 0))

        let subdomainsText = "URL have \(self.subdomainCount.description) subdomains"
        let subdomainsTag = ModuleTag(
            displayText: subdomainsText,
            risk: subdomainRisk,
            tagPriority: modulePriority.rawWithTag(tagPriotiry: 1))

        let lengthText = "URL have \(self.urlLength) characters"
        let lengthTag = ModuleTag(
            displayText: lengthText,
            risk: lengthRisk,
            tagPriority: modulePriority.rawWithTag(tagPriotiry: 2))

        let ipText = self.isIP ? "It's IP" : "It's Domain"
        let ipTag = ModuleTag(
            displayText: ipText,
            risk: ipRisk,
            tagPriority: modulePriority.rawWithTag(tagPriotiry: 3))

        return [prefixTag, subdomainsTag, lengthTag, ipTag]
    }
}

extension MLModule: ModuleTagBehavior {
    var risk: RiskLevel {
        guard let prediction = prediction else {
            return .danger
        }
        if prediction < 0.5 {
            return .common
        } else {
            return .danger
        }
    }
    
    var text: String {
        guard let prediction = prediction else {
            return "Not enough ML data"
        }
        return "􀫸 ML Trust: " + String(format: "%.0f", 100 - prediction*100) + "%"
    }
    
    var tags: [ModuleTag] {
        return [ ModuleTag(displayText: text, risk: risk, tagPriority: 9999) ]
    }
}
