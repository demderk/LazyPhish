//
//  PhishTableEntry.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import Foundation

struct PhishTableEntry: Identifiable {
    var uuid: UUID { UUID() }
    var id: Int
    var phishInfo: PhishInfo
}

extension PhishInfo {
//    func toTableEntry() -> PhishTableEntry {
//        ret
//    }
}
