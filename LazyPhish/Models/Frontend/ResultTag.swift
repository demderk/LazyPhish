//
//  ResultTag.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 22.04.2024.
//

import Foundation
import SwiftUI

struct MetricData {
    var risk: RiskLevel
    var value: String
}

enum Metric: Int, CaseIterable {
    case isIP = 3
    case haveWhois = 4
    case creationDate = 0
    case urlLength = 5
    case yandexSQI = 1
    case OPR = 2
    case prefixCount = 6
    case subDomainCount = 7
}

extension MLEntry {
    func getRisk(entry: Metric) -> RiskLevel {
        switch entry {
        case .isIP:
            self.isIP
        case .haveWhois:
            self.haveWhois
        case .creationDate:
            self.creationDate
        case .urlLength:
            self.urlLength
        case .yandexSQI:
            self.yandexSQI
        case .OPR:
            self.OPR
        case .prefixCount:
            self.prefixCount
        case .subDomainCount:
            self.subDomainCount
        }
    }
}

extension PhishInfo {
    func getMetricSet() -> [Metric: MetricData]? {
        guard let mlModel = self.getMLEntry() else {
            return nil
        }
        var metrics: [Metric: MetricData] = [:]
        for i in Metric.allCases {
            switch i {
            case .isIP:
                let risk = mlModel.getRisk(entry: i)
                let text = self.isIP ? "It's IP" : "It's Domain"
                metrics[i] = MetricData(risk: risk, value: text)
            case .haveWhois:
                let risk = mlModel.getRisk(entry: i)
                let text = self.whois == nil ? "Whois is empty" : "Whois found"
                metrics[i] = MetricData(risk: risk, value: text)
            case .creationDate:
                let risk = mlModel.getRisk(entry: i)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd MMMM yyyy"
                var text = "Creation data unavailable"
                dateFormatter.locale = Locale(identifier: "en_US")
                if let date = self.whois?.creationDate {
                    text = "Created: " + dateFormatter.string(from: date)
                }
                metrics[i] = MetricData(risk: risk, value: text)
            case .urlLength:
                let risk = mlModel.getRisk(entry: i)
                let text = "URL have \(self.urlLength) characters"
                metrics[i] = MetricData(risk: risk, value: text)
            case .yandexSQI:
                let risk = mlModel.getRisk(entry: i)
                let text = self.yandexSQI == nil ? "Yandex SQI is empty" : "Yandex SQI is \(self.yandexSQI!)"
                metrics[i] = MetricData(risk: risk, value: text)
            case .OPR:
                let risk = mlModel.getRisk(entry: i)
                let text = self.OPRRank == nil ? "OPR is empty" : "OPR Rank is \(self.OPRRank!)"
                metrics[i] = MetricData(risk: risk, value: text)
            case .prefixCount:
                let risk = mlModel.getRisk(entry: i)
                let text = "URL have \(self.prefixCount.description) prefix"
                metrics[i] = MetricData(risk: risk, value: text)
            case .subDomainCount:
                let risk = mlModel.getRisk(entry: i)
                let text = "URL have \(self.subDomainCount.description) subdomains"
                metrics[i] = MetricData(risk: risk, value: text)
            }
        }
        return metrics
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
        }
    }
}
