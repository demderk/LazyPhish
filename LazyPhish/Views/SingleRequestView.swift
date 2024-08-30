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
                            .fontWeight(.semibold)
                            .opacity(0.9)
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
                    }
                    .background(Color(nsColor: NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 16, height: 16)))
//                    HStack {
//                        Toggle("Deep Mode", isOn: $deepMode)
//                            .toggleStyle(BigToggleImageButton(
//                                image: Image(systemName: "sparkle.magnifyingglass")))
//                        Spacer()
//                    }.padding(.top, 4)
//                        .padding(.horizontal, 24)
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
                                Text(request.host)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .textCase(.lowercase)
                                    .offset(CGSize(width: 0, height: -2))
                                Spacer()
                            }.padding([.top], 16)
                                .padding([.bottom], 8)
                                .padding([.leading], 8)
                            PhishingCard(request: $vm.lastRequest, bussy: $vm.requestIsPending)
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
                            }, title: "Request Queue", imageSystemName: "tablecells")
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
