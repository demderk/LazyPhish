//
//  RemoteStatus.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import os

enum RemoteStatus {
    case planned
    case executing
    case completedWithErrors
    case completed
    case failed
    case canceled
}
