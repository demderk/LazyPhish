//
//  SingleRequestView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.04.2024.
//

import SwiftUI
import WrappingHStack
import AppKit

struct SingleRequestView: View {
    @ObservedObject var vm = SingleRequestViewModel()
    @FocusState var isEditing: Bool
    @EnvironmentObject var globalVM: GlobalVM
    
    @State var deepMode: Bool = false
    @State var errorsSheetPresented: Bool = false
    
    private let releaseColor: Color = .purple
    private let releaseName: String = "Release Candidate"
    
    var body: some View {
        ScrollView {
            // 100% horizontal space for scroll
            HStack {
                Spacer()
            }
            VStack {
                Spacer()
                    .frame(height: 112)
                HStack {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 64, height: 64)
                    Text("LazyPhish")
                        .font(.system(size: 48, weight: .heavy, design: .default))
                        .padding(.leading, 8)
                    Text(releaseName)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .foregroundStyle(releaseColor)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(releaseColor)
                        }
                        .offset(y: -4)
                }
                VStack {
                    HStack {
                        TextField("Make request", text: $vm.request)
                            .focused($isEditing)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .opacity(0.9)
                            .lineLimit(1)
                            .padding(.leading, 24)
                            .padding(.vertical, 21)
                            .onHover(perform: { hovering in
                                if hovering {
                                    NSCursor.iBeam.push()
                                } else {
                                    NSCursor.pop()
                                }
                            })
                            .onTapGesture {
                                isEditing = true
                            }
                            .onSubmit {
                                isEditing = false
                                vm.makeRequest()
                            }
                        Spacer()
                            .frame(maxWidth: 0)
                        Button(action: {
                            vm.makeRequest()
                        }, label: {
                            if !vm.requestIsPending {
                                Image(systemName: "arrow.forward")
                                    .font(.system(size: 17))
                                    .fontWeight(.bold)
                                    .padding([.horizontal], 24)
                                    .padding([.vertical], 23)
                            } else {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(
                                        CGSize(width: 0.6, height: 0.6))
                                    .frame(width: 17, height: 17)
                                    .padding([.horizontal], 24)
                                    .padding([.vertical], 23)
                            }
                        }).buttonStyle(.borderless)
                            .keyboardShortcut(.return)
                    }
                    .background(Color(nsColor: NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 16, height: 16)))
                    if let request = vm.lastRequest {
                        VStack {
                            HStack(alignment: .center) {
                                Text("LazyPhish")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                Spacer().frame(width: 8)
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .fontDesign(.default)
                                Spacer().frame(width: 8)
                                Text(request.url.cleanHost)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .textCase(.lowercase)
                                    .offset(CGSize(width: 0, height: -2))
                                Spacer()
                            }.padding([.top], 16)
                                .padding([.bottom], 8)
                                .padding([.leading], 8)
                            PhishingCard(request: $vm.lastRequest, bussy: $vm.requestIsPending)
                            HStack {
                                Spacer()
                                Text(vm.statusText)
                                    .foregroundStyle(Color(.lightGray))
                                    .onTapGesture {
                                        errorsSheetPresented = true
                                    }
                                    .popover(
                                        isPresented: $errorsSheetPresented,
                                        content: { PopupErrorView(request: vm.lastRequest!) }
                                    )
                            }.padding([.top], 2)
                                .padding([.horizontal], 4)
                        }
                    }
                    VStack {
                        HStack {
                            Text("Instruments")
                                .font(.title)
                                .fontWeight(.semibold)
                            Spacer()
                        }.padding(.top, 16)
                            .padding(.bottom, 8)
                            .padding(.leading, 8)
                        HStack {
                            PageButton(action: {
                                globalVM.navigation.append(MainSelectedPage.multi)
                            }, title: "Bulk Request", imageSystemName: "tablecells")
                            .padding([.horizontal], 16)
                            
                            Spacer()
                        }.padding(.horizontal, 16)
                    }
                }
                    .padding(.horizontal, 128)
                Spacer()
            }.navigationTitle("Home")
        }
        .alert("Setup incomplete", isPresented: $vm.incompleteSetup, actions: {
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("Go To Settings")
                }
            } else {
                Button("Go To Settings") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }
            Button("Cancel", role: .cancel) { vm.incompleteSetup = false }
        }, message: {
            Text("""
                 LazyPhish can't process the request because the setup is incomplete.
                 Go to Settings -> Keys and configure the required keys.
                 """)
        })
    }
}

struct PopupErrorView: View {
    var request: RemoteRequest
    
    private var failedModules: [RequestModule] {
        request.modules.filter({ x in x.failed })
    }
    
    private var completedWithErrorsModules: [RequestModule] {
        request.modules.filter({ x in x.completedWithErrors })
    }
    
    struct ErrorText: Identifiable {
        var id: UUID { UUID() }
        
        var name: String
        var errorText: String
    }
    
    private var moduleErrorsText: [ErrorText] {
        var result: [ErrorText] = []
        for failedModule in failedModules {
            let name = String(describing: failedModule)
            var errors: [String] = []
            switch failedModule.status {
            case .failed(let error):
                errors.append(error.localizedDescription)
            case .completedWithErrors(let moduleErrors):
                if let moduleErrors = moduleErrors {
                    errors.append(contentsOf: moduleErrors.map({ $0.localizedDescription }))
                } else {
                    errors.append("empty error (nil)")
                }
            default:
                break
            }
            result.append(ErrorText(name: name, errorText: errors.joined(separator: "\n")))
        }
        return result
    }
    
    private var moduleWarningsText: [ErrorText] {
        var result: [ErrorText] = []
        for failedModule in completedWithErrorsModules {
            let name = String(describing: failedModule)
            var errors: [String] = []
            switch failedModule.status {
            case .completedWithErrors(let moduleErrors):
                if let moduleErrors = moduleErrors {
                    errors.append(contentsOf: moduleErrors.map({ $0.localizedDescription }))
                } else {
                    errors.append("empty error (nil)")
                }
            default:
                break
            }
            result.append(ErrorText(name: name, errorText: errors.joined(separator: "\n")))
        }
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Spacer().frame(height: 8)
                if moduleErrorsText.isEmpty && moduleWarningsText.isEmpty {
                    Spacer().frame(height: 12)
                    HStack(alignment: .center) {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .fontWeight(.black)
                        Spacer().frame(width: 8)
                        Text("No errors found")
                    }
                }
                if !moduleErrorsText.isEmpty {
                    Spacer().frame(height: 16)
                    HStack(alignment: .center) {
                        Image(systemName: "xmark.circle.fill")
                            .fontWeight(.semibold)
                            .symbolRenderingMode(.multicolor)
                        Spacer().frame(width: 6)
                        Text("\(moduleErrorsText.count) Errors")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }.offset(x: -6)
                    HStack {
                        Spacer().frame(width: 32)
                        VStack(alignment: .leading) {
                            ForEach(moduleErrorsText) { modErr in
                                Spacer().frame(height: 8)
                                Text(modErr.name)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(modErr.errorText)
                            }
                        }
                    }
                }
                if !moduleWarningsText.isEmpty {
                    Spacer().frame(height: 16)
                    HStack(alignment: .center) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .fontWeight(.semibold)
                            .symbolRenderingMode(.multicolor)
                        Spacer().frame(width: 6)
                        Text("\(moduleWarningsText.count) Warnings")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }.offset(x: -6)
                    HStack {
                        Spacer().frame(width: 32)
                        VStack(alignment: .leading) {
                            ForEach(moduleWarningsText) { modErr in
                                Spacer().frame(height: 8)
                                Text(modErr.name)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(modErr.errorText)
                            }
                        }
                    }
                }
            }.padding([.horizontal, .bottom], 24)
        }.frame(maxWidth: 600, maxHeight: 600)
    }
}

#Preview {
    SingleRequestView()
        .frame(minWidth: 1000, minHeight: 600)
}
