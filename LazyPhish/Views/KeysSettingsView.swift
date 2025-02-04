//
//  KeySettingsPage.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 26.08.2024.
//

import SwiftUI
import LocalAuthentication

struct KeysSettingsView: View {
    @Environment(\.controlActiveState) var state

    @State var VTKey: String = ""
    @State var abuseIPKey: String = ""
    @State var OPRKey: String = ""
    @State var access: Bool = false
    @State var saveMode: Bool = false

    @FocusState var vtFieldFocus: Bool
    @FocusState var oprFieldFocus: Bool

    var securedBody: some View {
        VStack(alignment: .trailing) {
            VStack {
                VStack {
                    HStack {
                        Spacer()
                        Text("Open Page Rank Key:")
                        TextField("6biG9Bnc8EUU6rFH123F7TsDm69bazElgM6M65i", text: $OPRKey)
                            .frame(width: 512)
                            .textFieldStyle(.squareBorder)
                            .focused($oprFieldFocus)
                            .onChange(of: oprFieldFocus) { _ in
                                if !saveMode {
                                    saveMode = !saveMode
                                }
                            }
                        Link(destination: URL(string: "https://www.domcop.com/openpagerank/what-is-openpagerank")!) {
                            Image(systemName: "questionmark.circle")
                                .imageScale(.medium)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.secondary)
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .help("What is OpenPageRank?")
                    }
                }.padding(.horizontal, 32)
                    .focused($vtFieldFocus)
                    .padding(.bottom, 16)
                #if RELEASE
                HStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .imageScale(.medium)
                        .symbolRenderingMode(.hierarchical)
                        .fontWeight(.black)
                    Spacer().frame(width: 4)
                    // swiftlint:disable:next line_length
                    Text("You are using the community version of LazyPhish that does not support encryption for keys.")
                    Spacer()
                }.foregroundStyle(.secondary)
                Spacer().frame(height: 16)
                #endif
                Divider()
                HStack {
                    Button(action: {
                        lockKeys()
                    }, label: {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.primary.opacity(0.8))
                            Divider().frame(height: 16)
                            Text("Lock Keychain")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
                    })
                        .buttonStyle(.plain)
                    Spacer()
                }.padding(.top, 8)
            }
        }.onAppear {
            KeyService.readKeychainKey(path: .opr) { key in
                if let val = key {
                    OPRKey = val
                }
            }
            KeyService.readKeychainKey(path: .virusTotal) { key in
                if let val = key {
                    VTKey = val
                }
            }
        }
    }

    var body: some View {
        Group {
            if !access {
                VStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(.gray)
                        .opacity(0.3)
                        .padding(.bottom, 8)
                    Text("Keys Are Locked")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer().frame(height: 4)
                    Text("Touch ID or enter password to unlock.")
                    Spacer().frame(height: 16)
                    Button("Authenticate") {
                        auth()
                    }
                }.padding(.vertical, 64)
                    .onAppear {
                        auth()
                    }
            } else {
                securedBody
            }
        }.onChange(of: state) { _ in
            if saveMode {
                KeyService.saveAllKeys(virusTotal: VTKey, opr: OPRKey)
            }
        }.onDisappear {
            if saveMode {
                KeyService.saveAllKeys(virusTotal: VTKey, opr: OPRKey)
            }
        }
    }

    func lockKeys() {
        access = false
        saveMode = false
    }

    func auth() {
        let authObject = LAContext()
        var error: NSError?

        if authObject.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            authObject.evaluatePolicy(.deviceOwnerAuthentication,
                                      localizedReason: "access keys") { success, _ in
                if success {
                    access = true
                }

            }
        }
    }
}
#Preview {
    KeysSettingsView()
}
