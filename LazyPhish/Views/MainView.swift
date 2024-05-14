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
                vm.pageHolder.single
                    .environmentObject(globalVM)
                    .navigationDestination(for: MainSelectedPage.self) { page in
                        switch page {
                        case .multi:
                            vm.pageHolder.multi
                                .environmentObject(globalVM)
                        case .single:
                            vm.pageHolder.single
                                .environmentObject(globalVM)
                        case .server:
                            vm.pageHolder.server
                                .environmentObject(globalVM)
                        }
                        
                        //                        Spacer()
                        
                    }.frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .center
                      )
        }.toolbar {
            Text("")
        }
    }
}

#Preview {
    MainView()
        .frame(minWidth: 1000, minHeight: 600)
}
