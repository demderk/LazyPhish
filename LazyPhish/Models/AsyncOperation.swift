//
//  AsyncOperation.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.09.2024.
//

import Foundation

class AsyncOperation: Operation {
    override var isAsynchronous: Bool {
        return true
    }
    // swiftlint:disable all
    var _isFinished: Bool = false
    
    override var isFinished: Bool {
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
        
        get {
            return _isFinished
        }
    }

    var _isExecuting: Bool = false
    
    override var isExecuting: Bool {
        set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
        
        get {
            return _isExecuting
        }
    }
}
