//
//  ServerView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 14.05.2024.
//

import SwiftUI

struct ServerView: View {
    @ObservedObject var vm = ServerVM()
    
    var body: some View {
        VStack {
            Button("Start") {
                vm.createServer()
            }
            Button("stop") {
                vm.stop()
            }
        }.background(.white)
            .frame(alignment: .center)
    }
}

#Preview {
    ServerView()
        .frame(minWidth: 1000, minHeight: 600)
}
