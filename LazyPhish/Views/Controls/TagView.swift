//
//  TagView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 26.09.2024.
//

import Foundation
import SwiftUI

struct TagView: View {
    @State var tag: ModuleTag

    var body: some View {
        Text(tag.displayText)
            .font(.body)
            .fontWeight(.semibold)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding([.horizontal], 8)
            .padding([.vertical], 4)
            .background(tag.color)
            .clipShape(
                RoundedRectangle(
                    cornerSize:
                        CGSize(
                            width: 16,
                            height: 16)))
            .padding([.vertical], 8)

    }
}
