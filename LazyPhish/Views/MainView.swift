//
//  MainView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.04.2024.
//

import SwiftUI

struct MainView: View {
    @StateObject var vm = MainViewVM()
    @StateObject var globalVM = GlobalVM()
    
    var body: some View {
        NavigationStack(path: $globalVM.navigation) {
            SingleRequestView()
                .environmentObject(globalVM)
                .navigationDestination(for: MainSelectedPage.self) { page in
                    switch page {
                    case .multi:
                        MultiRequestView()
                            .environmentObject(globalVM)
                    case .single:
                        SingleRequestView()
                            .environmentObject(globalVM)
                    }
                }
        }.toolbar {
            Text("")
        }
    }
}

#Preview {
    MainView()
        .frame(minWidth: 1000, minHeight: 600)
}
