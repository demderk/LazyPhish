//
//  SettingsView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 19.08.2024.
//

import SwiftUI
import AppKit
import LocalAuthentication
import Cocoa

struct SettingsView: View {
    var body: some View {
        TabView {
            Text("General").tabItem {
                Label("General", systemImage: "gear")
            }
            KeysSettingsView()
                .tabItem {
                    Label("Keys", systemImage: "key")
                }
        }.scenePadding()
            .frame(width: 800)
    }
}

#Preview {
    SettingsView()
}
