//
//  RemoteJobStatus.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 07.12.2024.
//

enum RemoteJobStatus {
    case planned
    case executing
    case canceled
    case excalated
    case failed(_ error: RemoteJobError)
    case completedWithErrors(_ errors: [RemoteJobError]? = nil)
    case completed
    
    /// The job is finished if it is either `.completed` or `.completedWithErrors`.
    var isFinished: Bool {
        switch self {
        case .completedWithErrors(let errors):
            fallthrough
        case .completed:
            return true
        default:
            return false
        }
    }
    
    /// Is true when the status is .completedWithErrors.
    var completedWithErrors: Bool {
        if case .completedWithErrors = self {
            return true
        } else { return false }
    }
    
    /// Is true when the status is .complete.
    var isCompleted: Bool {
        if case .completed = self {
            return true
        } else { return false }
    }
    
    /// Is true when the status is .failed.
    var isFailed: Bool {
        if case .failed = self {
            return true
        } else { return false }
    }
}
