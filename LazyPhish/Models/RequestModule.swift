//
//  RequestModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

protocol RequestModule {
    var dependences: [any RequestModule] { get set}
    var status: ModuleStatus { get }

    func execute(remote: RequestInfo) async
    func execute(remote: RequestInfo, onFinish: (RequestInfo, RequestModule) -> Void) async
}

extension RequestModule {
    func execute(remote: RequestInfo, onFinish: (RequestInfo, RequestModule) -> Void) async {
        await execute(remote: remote)
        onFinish(remote, self)
    }
}
