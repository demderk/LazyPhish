//
//  MLModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 09.10.2024.
//

import Foundation

enum MLError: RequestError {
    case modulesNotFinished
}

struct MLEntry {
    var OPRScore: Int
    var SQIScore: Int
    var haveWhois: Bool
    var date: Date
    var hostLength: Int
    var subdomains: Int
}

extension MLEntry {
    init(remote: RequestInfo) throws {
        guard let oprModule = remote.getCompletedModule(module: OPRModule.self),
              let sqiModule = remote.getCompletedModule(module: SQIModule.self),
              let whoisModule = remote.getCompletedModule(module: WhoisModule.self),
              let regexModule = remote.getCompletedModule(module: RegexModule.self)
        else {
            throw MLError.modulesNotFinished
        }

        OPRScore = oprModule.rank ?? -1
        SQIScore = sqiModule.yandexSQI ?? -1
        haveWhois = whoisModule.whois != nil
        date = whoisModule.whois?.creationDate ?? Date(timeIntervalSinceReferenceDate: 0)
        hostLength = regexModule.hostLength
        subdomains = regexModule.subdomainCount
    }
}

class MLModule: RequestModule {
    var dependences: DependencyCollection = DependencyCollection([
        OPRModule(),
        SQIModule(),
        WhoisModule(),
        RegexModule()
    ])

    var status: ModuleStatus = .planned
    var prediction: Bool?
    var predictionPercent: Int?

    func execute(remote: RequestInfo) async {
        status = .executing

//        LazyPhishML

        status = .completed
    }

}
