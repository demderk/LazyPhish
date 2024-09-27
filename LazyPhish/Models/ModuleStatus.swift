//
//  ModuleStatus.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

enum ModuleStatus {
    case planned
    case executing
    case excalated
    case failed(error: RequestError)
    case canceled
    case completed
}
