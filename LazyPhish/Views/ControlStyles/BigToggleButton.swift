//
//  BigToggleButton.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 27.08.2024.
//

import SwiftUI

struct BigImageButton: ButtonStyle {
    @State var image: Image

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            image
                .foregroundStyle(.primary.opacity(0.8))
            Divider().frame(height: 16)
            configuration.label
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.gray.opacity(0.1) )
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
        .opacity(configuration.isPressed ? 0.80 : 1)
    }
}

struct BigButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.gray.opacity(0.1) )
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
        .opacity(configuration.isPressed ? 0.80 : 1)
    }
}

struct BigToggleButton: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            configuration.label
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(configuration.isOn ? .white : .black)
                .background(configuration.isOn ? .blue.opacity(1) : .gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
        }).buttonStyle(.plain)
    }
}

struct BigToggleImageButton: ToggleStyle {
    @State var image: Image

    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            HStack {
                image
                    .foregroundStyle(configuration.isOn ? .white : .black)
                    .fontWeight(.semibold)
//                    .font(.title2)
                    .padding(4)
                    .foregroundStyle(configuration.isOn ? .white : .black)
                    .background(configuration.isOn ? .blue.opacity(1) : .gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
                configuration.label
            }
        }).buttonStyle(.plain)
    }
}
