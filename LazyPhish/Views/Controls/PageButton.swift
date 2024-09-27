//
//  PageButton.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 19.08.2024.
//

import SwiftUI

struct PageButton: View {
    @State var action: () -> Void
    @State var title: String
    @State var imageSystemName: String

    var body: some View {
        Button(action: action, label: {
            VStack {
                Image(systemName: imageSystemName)
                    .font(.system(size: 32))
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                    .aspectRatio(contentMode: .fit)
                    .padding([.vertical], 16)
                    .padding([.leading], 9)
                    .padding([.trailing], 8)
                    .frame(width: 72, height: 72)
                    .background(
                        Color(
                            nsColor: NSColor.systemBlue.withAlphaComponent(0.08)))
                    .clipShape(
                        RoundedRectangle(
                            cornerSize:
                                CGSize(width: 16,
                                       height: 16)))
                Text(title)
                    .padding([.top], 1)
                    .offset(CGSize(width: 2, height: 0))
            }
        }).buttonStyle(.plain)
    }
}

#Preview {
    PageButton(action: {}, title: "TestName", imageSystemName: "antenna.radiowaves.left.and.right")
}
