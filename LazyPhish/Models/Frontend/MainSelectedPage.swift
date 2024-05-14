//
//  MainSelectedPage.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 20.04.2024.
//

import Foundation
import SwiftUI

enum MainSelectedPage: CaseIterable, Identifiable {
    var id: Self { return self }
    
    case single
    case multi
    case server
    
    var title: String {
        switch self {
        case .single:
            "Single Request"
        case .multi:
            "Multi Request"
        case .server:
            "Reflector Server"
        }
    }
}
