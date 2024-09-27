//
//  RegexModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation

class RegexModule: RequestModule {
    var dependences: [any RequestModule] = []
    var status: ModuleStatus = .planned

    private var url: StrictURL!

    var isIP: Bool { PhishInfoFormatter.getURLIPMode(url.URL) }
    var urlLength: Int { url.URL.formatted().count }
    var prefixCount: Int { url.URL.formatted().components(separatedBy: ["-"]).count - 1 }
    var subdomainCount: Int {
        url.URL.host()!
            .replacing("www.", with: "")
            .components(separatedBy: ["."])
            .count - 2
    }

    init(url: StrictURL) {
        self.url = url
        status = .completed
    }

    init() {

    }

    func execute(remote: RemoteInfo) async {
        url = remote.url
        status = .completed
    }

}
