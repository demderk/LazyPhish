//
//  RegexModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation

class RegexModule: RequestModule {
    var dependences: DependencyCollection = DependencyCollection()
    var status: ModuleStatus = .planned

    private var url: StrictURL!

    var isIP: Bool { PhishInfoFormatter.getURLIPMode(url.URL) }
    var urlLength: Int { url.cleanURL.count }
    var hostLength: Int { url.cleanHost.count }
    var prefixCount: Int { url.strictHost.components(separatedBy: ["-"]).count - 1 }
    var subdomainCount: Int {
        url.cleanHost
            .components(separatedBy: ["."])
            .count - (url.isTwoSLD ? 3 : 2)
    }

    init(url: StrictURL) {
        self.url = url
        status = .completed
    }

    init() {

    }

    func execute(remote: RequestInfo) async {
        url = remote.url
        status = .completed
    }

}
