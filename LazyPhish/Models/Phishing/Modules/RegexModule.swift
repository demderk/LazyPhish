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
    var urlLength: Int { url.URL.formatted().count }
    var hostLength: Int { url.strictHost.count }
    var prefixCount: Int { url.URL.formatted().components(separatedBy: ["-"]).count - 1 }
    var subdomainCount: Int {
        url.URL.host()!
            .replacing("www.", with: "") // [INSECURE] Это в будующем может быть путем обхода
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
