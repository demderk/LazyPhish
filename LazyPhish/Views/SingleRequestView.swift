//
//  SingleRequestView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.04.2024.
//

import SwiftUI
import WrappingHStack

struct SingleRequestView: View {
    @ObservedObject var vm = SingleRequestViewModel()
    @FocusState var isEditing: Bool
    @EnvironmentObject var globalVM: GlobalVM
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
            }
            VStack {
                Spacer()
                    .frame(height: 112)
                VStack {
                    Text("LazyPhish")
                        .font(.system(size: 48, weight: .heavy, design: .default))
                        .padding([.bottom], 2)
                    Text("Phishing Security. Evolved.")
                        .font(.title2)
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
                            Button(action: {
                                globalVM.navigation.append(MainSelectedPage.multi)
                            }, label: {
                                VStack {
                                    Image(systemName: "tablecells")
                                        .font(.system(size: 32))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                        .aspectRatio(contentMode: .fit)
                                        .padding([.vertical], 16)
                                        .padding([.leading], 9)
                                        .padding([.trailing], 8)
                                        .frame(width: 64, height: 68)
                                        .background(
                                            Color(
                                                nsColor:
                                                    NSColor.systemBlue.withAlphaComponent(0.08)))
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerSize:
                                                    CGSize(
                                                        width: 16,
                                                        height: 16)))
                                    Text("Make Querry")
                                        .padding([.top], 1)
                                        .offset(CGSize(width: 2, height: 0))
                                }
                            }).buttonStyle(.plain)
                                .padding([.horizontal], 16)
                            Button(action: {
                                globalVM.navigation.append(MainSelectedPage.server)
                            }, label: {
                                VStack {
                                    Image(systemName: "rectangle.and.text.magnifyingglass")
                                        .font(.system(size: 32))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                        .aspectRatio(contentMode: .fit)
                                        .padding([.vertical], 16)
                                        .padding([.leading], 9)
                                        .padding([.trailing], 8)
                                        .frame(width: 64, height: 72)
                                        .background(
                                            Color(
                                                nsColor: NSColor.systemBlue.withAlphaComponent(0.08)))
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerSize:
                                                    CGSize(width: 16,
                                                           height: 16)))
                                    Text("Onlooker")
                                        .padding([.top], 1)
                                        .offset(CGSize(width: 2, height: 0))
                                }
                            }).buttonStyle(.plain)
                                .padding([.horizontal], 16)
                            
                            Spacer()
                        }.padding([.horizontal], 16)
                    }
                }.frame(maxWidth: 640)
                    .padding([.horizontal], 256)
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
