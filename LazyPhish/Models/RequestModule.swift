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

    func execute(remote: RemoteInfo) async
}
