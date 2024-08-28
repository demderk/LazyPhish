//
//  StatusView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 19.08.2024.
//

import SwiftUI

//struct StatusViewConfig {
//    var
//}

struct StatusView: View {
    @Binding var busy: Bool
    @Binding var iconName: String
    @Binding var status: String
    
    var body: some View {
        HStack {
            if busy {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(
                        CGSize(width: 0.5, height: 0.5))
                    .frame(width: 17, height: 17)
            } else {
                Image(systemName: iconName)
            }
            Text(status)
        }
        .padding(4)
        .padding(.trailing, 4)
        .padding(.horizontal, 8)
        .background(Color(
            nsColor: NSColor.lightGray.withAlphaComponent(0.1)))
        .clipShape(Capsule())
    }
}

#Preview {
    StatusView(busy: .constant(true), iconName: .constant("pencil"), status: .constant("Setup"))
}
