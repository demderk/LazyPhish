//
//  MLModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 28.10.2024.
//

import Foundation
import CoreML
import OSLog

extension PhishingEntry {
    var MLInput: PhishMLInput {
        PhishMLInput(
            hostLength: Int64(hostLength),
            urlLength: Int64(urlLength),
            sqi: Int64(sqi),
            subDomains: Int64(subDomains),
            prefixCount: Int64(prefixCount),
            whoisBlinded: Int64(whoisBlinded ? 1 : 0),
            dateFromNow: Double(dateFromNow),
            opr: Int64(opr))
    }
}

enum MLError: ModuleError {
    case modulesNotFinished
    case modelInitFailed
}

class MLModule: RequestModule {
    var dependences: DependencyCollection = DependencyCollection([
        SQIModule(),
        OPRModule(),
        RegexModule(),
        WhoisModule()
    ])
    
    var status: RemoteJobStatus = .planned
    var prediction: Double?
    private var model: PhishML?
    
    init() {
        do {
            try self.model = PhishML(configuration: MLModelConfiguration())
        } catch {
            Logger.MLModelLogger.error("PhishML | LazyPhishML | Initialization error")
        }
    }
    
    func execute(remote: RemoteRequest) async {
        guard await dependences.finished else {
            status = .failed(MLError.modulesNotFinished)
            return
        }
        guard model != nil else {
            status = .failed(MLError.modelInitFailed)
            return
        }
        
        guard let oprModule = await dependences.getDependency(module: OPRModule.self),
              let sqiModule = await dependences.getDependency(module: SQIModule.self),
              let whoisModule = await dependences.getDependency(module: WhoisModule.self),
              let regexModule = await dependences.getDependency(module: RegexModule.self)
        else {
            status = .failed(MLError.modelInitFailed)
            return
        }
        
        let phishData = PhishingEntry(
            id: 0,
            host: remote.host,
            hostLength: regexModule.hostLength,
            url: remote.url.URL.description,
            urlLength: regexModule.urlLength,
            whoisFound: whoisModule.whoisFound,
            whoisBlinded: whoisModule.blinded,
            date: whoisModule.date,
            sqi: sqiModule.yandexSQI ?? -1,
            opr: oprModule.rank ?? -1,
            subDomains: regexModule.subdomainCount,
            prefixCount: regexModule.prefixCount,
            isIP: regexModule.isIP)
        
        prediction = predictPhishing(input: phishData).isPhishingProbability[1]
        status = .completed
    }
    
    func predictPhishing(input: PhishingEntry) -> PhishMLOutput {
        if let model = model, let predicion = try? model.prediction(input: input.MLInput) {
            return predicion
        }
        fatalError("err")
    }
}
