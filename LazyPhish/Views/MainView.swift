//
//  MainView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.04.2024.
//

import SwiftUI

struct MainView: View {
    @StateObject var vm = MainViewVM()
    
    var body: some View {
        NavigationSplitView(sidebar: {
            List(MainSelectedPage.allCases, selection: $vm.selectedPage) { item in
                Text(item.title)
            }
        }, detail: {
            vm.getPage()
        })
    }
}

#Preview {
    MainView()
        .frame(minWidth: 1000, minHeight: 600)
}
