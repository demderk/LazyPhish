//
//  RemoteInfo.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation

class RemoteInfo {
    // TODO: Make private(set)

    private(set) var modules: [any RequestModule] = []

    var requestID: Int?
    var url: StrictURL
    var status: RemoteStatus = .planned

    init(url: StrictURL) {
        self.url = url
    }

    func executeAll() async {
        status = .executing
        await withTaskGroup(of: Void.self) { tasks in
            for mod in modules {
                _ = tasks.addTaskUnlessCancelled {
                    await mod.execute(remote: self)
                }
            }
        }
        if modules.count(where: {
            if case ModuleStatus.failed(_) = $0.status {
                return true
            }
            return false
        }) > 0 {
            status = .completedWithErrors
        } else {
            status = .completed
        }
    }

    func addModule(_ module: any RequestModule) {
        modules.append(module)
    }

    func addModule(contentsOf: [any RequestModule]) {
        modules.append(contentsOf: contentsOf)
    }

//    func getMLEntry() -> MLEntry {
//        if status == .completed {
//            return MLEntry(<#T##phishInfo: PhishInfo##PhishInfo#>)
//        }
//    }
}
