//
//  MainViewVM.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.04.2024.
//
import Foundation
import SwiftUI

class MainViewVM: ObservableObject {
    @Published var selectedPage: MainSelectedPage = .single
    init() { }
    
    var pageHolder = MainViewPageHolder()
    
    @ViewBuilder func getPage() -> some View {
        pageHolder.getView(selected: selectedPage)
    }
}

