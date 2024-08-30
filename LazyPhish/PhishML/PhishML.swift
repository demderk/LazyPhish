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

extension MLEntry {
    var MLInput: LazyPhishMLInput {
        LazyPhishMLInput(
            isIP: isIP.raw64,
            haveWhois: haveWhois.raw64,
            creationDate: creationDate.raw64,
            urlLength: urlLength.raw64,
            yandexSQI: yandexSQI.raw64,
            OPR: OPR.raw64,
            prefixCount: prefixCount.raw64,
            subDomainCount: subDomainCount.raw64
        )
    }
}

class PhishML {
    private var model = LazyPhishML()
    
    init() {
        do {
            try self.model = LazyPhishML(configuration: MLModelConfiguration())
        } catch {
            Logger.MLModelLogger.error("PhishML | LazyPhishML | Initialization error")
        }
    }
    
    func predictPhishing(input: MLEntry) -> LazyPhishMLOutput {
        if let predicion = try? model.prediction(input: input.MLInput) {
            return predicion
        }
        fatalError("err")
    }
}
