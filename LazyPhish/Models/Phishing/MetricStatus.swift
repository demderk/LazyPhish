//
//  MetricStatus.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 16.03.2024.
//

import Foundation

enum MetricStatus<T> {
    case planned
    case success(value: T)
    case failed(error: RequestError)
    
    var value: T? {
        switch self {
        case .planned:
            return nil
        case .success(let value):
            return value
        case .failed:
            return nil
        }
    }
    
    var error: RequestError? {
        switch self {
        case .planned:
            return nil
        case .success:
            return nil
        case .failed(let value):
            return value
        }
    }
}
