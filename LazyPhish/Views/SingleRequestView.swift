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
    @State var deepMode2: Bool = false
    @State var deepMode3: Bool = false
    
    var body: some View {
        ScrollView {
            // 100% horizontal space for scroll
            HStack {
                Spacer()
            }
            VStack {
                Spacer()
                    .frame(height: 112)
                VStack {
//                    Image("logo")
//                        .resizable()
//                        .frame(
//                            width: 80,
//                            height: 80)
//                    Spacer().frame(width: 16)
                    VStack {
                        Text("LazyPhish")
                            .font(.system(size: 48, weight: .heavy, design: .default))
                            .padding([.bottom], 2)
                        Text("Phishing Security. Evolved.")
                            .font(.title2)
                    }
                }
                VStack {
                    HStack {
                        TextField("Make request", text: $vm.request)
                            .focused($isEditing)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .lineLimit(1)
                            .padding([.leading], 24)
                            .padding([.vertical], 21)
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
                            Image(systemName: "arrow.forward")
                                .font(.system(size: 17))
                                .fontWeight(.bold)
                                .padding([.horizontal], 24)
                                .padding([.vertical], 23)
                        }).buttonStyle(.borderless)
                    }
                    .background(Color(nsColor: NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 16, height: 16)))
                    HStack {
//                        Spacer()
                        Toggle("Deep Mode", isOn: $deepMode)
                            .toggleStyle(BigToggleImageButton(image: Image(systemName: "sparkle.magnifyingglass")))
                        Toggle("LazyPhish AI", isOn: $deepMode2)
                            .toggleStyle(BigToggleImageButton(image: Image(systemName: "sparkle")))
                        Toggle("Lookyloo", isOn: $deepMode3)
                            .toggleStyle(BigToggleImageButton(image: Image(systemName: "eyes")))
                        Spacer()
                    }.padding(.top, 4)
                     .padding(.horizontal, 24)
                    if let haveResult = vm.lastRequest {
                        VStack {
                            HStack {
                                Text("Request Result")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                Spacer()
                            }.padding([.top], 16)
                                .padding([.bottom], 8)
                                .padding([.leading], 8)
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(haveResult.host)
                                            .textCase(.uppercase)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        
                                        WrappingHStack(vm.tagList, id: \.self) { tag in
                                            Text(tag.value)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .lineLimit(1)
                                                .fixedSize(horizontal: true, vertical: false)
                                                .padding([.horizontal], 8)
                                                .padding([.vertical], 4)
                                                .background(tag.risk.getColor())
                                                .clipShape(
                                                    RoundedRectangle(
                                                        cornerSize:
                                                            CGSize(
                                                                width: 16,
                                                                height: 16)))
                                                .padding([.vertical], 8)
                                        }.frame(minWidth: 512)
                                    }.padding(16)
                                    //                                Spacer()
                                }
                            }
                            .background(Color(nsColor: NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 16, height: 16)))
                        }
                    }
                    VStack {
                        HStack {
                            Text("Instruments")
                                .font(.title)
                                .fontWeight(.semibold)
                            Spacer()
                        }.padding([.top], 16)
                            .padding([.bottom], 8)
                            .padding([.leading], 8)
                        HStack {
                            PageButton(action: {
                                globalVM.navigation.append(MainSelectedPage.multi)
                            }, title: "Reflector", imageSystemName: "tablecells")
                                .padding([.horizontal], 16)
                            PageButton(action: {
                                globalVM.navigation.append(MainSelectedPage.server)
                            }, title: "Reflector", imageSystemName: "antenna.radiowaves.left.and.right")
                                .padding([.horizontal], 16)
                            
                            Spacer()
                        }.padding([.horizontal], 16)
                    }
                }.frame(maxWidth: 640)
                    .padding([.horizontal], 64)
                    .padding([.vertical], 32)
                Spacer()
            }.navigationTitle("Home")
        }
    }
}

#Preview {
    SingleRequestView()
        .frame(minWidth: 1000, minHeight: 600)
}
