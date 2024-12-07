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
    case completedWithErrors(errors: [Error]? = nil)
    case completed
    
    /// If status equal completed or completedWithErrors
    var justCompleted: Bool {
        switch self {
        case .completedWithErrors(let errors):
            fallthrough
        case .completed:
            return true
        default:
            return false
        }
    }
}
