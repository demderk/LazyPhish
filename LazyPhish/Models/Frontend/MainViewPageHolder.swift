//
//  MainViewPageHolder.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 20.04.2024.
//

import Foundation
import SwiftUI

class MainViewPageHolder: ObservableObject {
    var multi: some View = MultiRequestView()
    var single: some View = SingleRequestView()
    var server: some View = ServerView()
    
    @ViewBuilder func getView(selected: MainSelectedPage) -> some View {
        switch selected {
        case .single:
            single
        case .multi:
            multi
        case .server:
            server
        }
    }
}
