//
//  MultiRequestView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import SwiftUI

struct MultiRequestView: View {
    @ObservedObject var vm = MultiRequestVM()
    @State var showExport = false
    @State var sortingTable = [KeyPathComparator(\PhishInfo.requestID, order: .forward)]
    
    @ViewBuilder
    var body: some View {
        HSplitView {
            VStack {
                HStack {
                    Spacer()
                    Text("Request Body")
                        .font(.callout)
                        .padding(6)
                        .lineLimit(1)
                    Spacer()
                }.background(.background)
                Spacer().frame(height: 0)
                Divider()
                Spacer().frame(height: 0)
                TextEditor(text: $vm.requestText)
                    .font(.body)
                    .lineSpacing(5)
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
                    .background(.background)
            }.frame(minWidth: 64)
            HStack {
                Table(of: PhishInfo.self, sortOrder: $sortingTable) {
                    TableColumn("ID", value: \.requestID!) { type in
                        Text(type.requestID?.description ?? "Error")
                    }.width(min: 32, ideal: 32)
                    TableColumn("Url", value: \.host) { type in
                        Text(type.url.formatted())
                    }.width(min: 144, ideal: 192)
                    TableColumn("yandexSQI", value: \.sortSqiInt) { type in
                        VStack {
                            Text(type.yandexSQI?.formatted() ??
                                 (type.remote.yandexSQI.error?.localizedDescription ??
                                  "Ureachable"))
                            .padding(.horizontal, 4)
                            .background(type.getMLEntry()?.yandexSQI.getColor() ?? .blue)
                            .clipShape(Capsule())
                            
                        }
                    }.width(min: 64, ideal: 64)
                    TableColumn("OPR Rank", value: \.sortOprInt) { type in
                        Text(type.OPR?.rank?.description ??
                             (type.remote.OPR.error?.localizedDescription ??
                              "Ureachable"))
                        .padding(.horizontal, 4)
                        .background(type.getMLEntry()?.OPR.getColor() ?? .blue)
                        .clipShape(Capsule())
                    }.width(min: 64, ideal: 64)
                    TableColumn("Creation Date", value: \.sortDate) { type in
                        Text(type.creationDate?.formatted() ??
                             (type.remote.whois.error?.localizedDescription ??
                              "Ureachable"))
                        .padding(.horizontal, 4)
                        .background(type.getMLEntry()?.creationDate.getColor() ?? .blue)
                        .clipShape(Capsule())
                    }.width(min: 120, ideal: 120)
                    TableColumn("Have Whois", value: \.sortHaveWhois) { type in
                        Text(type.whois != nil ? "Yes" : "No")
                            .padding(.horizontal, 4)
                            .background(type.getMLEntry()?.haveWhois.getColor() ?? .blue)
                            .clipShape(Capsule())
                    }.width(min: 72, ideal: 72)
                    TableColumn("Is IP", value: \.sortIsIP) { type in
                        Text(type.isIP ? "Yes" : "No")
                            .padding(.horizontal, 4)
                            .background(type.getMLEntry()?.isIP.getColor() ?? .blue)
                            .clipShape(Capsule())
                        
                    }.width(min: 40, ideal: 40)
                    TableColumn("Prefixes", value: \.prefixCount) { type in
                        Text(type.prefixCount.description)
                            .padding(.horizontal, 4)
                            .background(type.getMLEntry()?.prefixCount.getColor() ?? .blue)
                            .clipShape(Capsule())
                    }.width(min: 48, ideal: 48)
                    TableColumn("Subdomains", value: \.subDomainCount) { type in
                        Text(type.subDomainCount.description)
                            .padding(.horizontal, 4)
                            .background(type.getMLEntry()?.subDomainCount.getColor() ?? .blue)
                            .clipShape(Capsule())
                    }.width(min: 72, ideal: 72)
                    TableColumn("URL Length", value: \.urlLength) { type in
                        Text(type.urlLength.description)
                            .padding(.horizontal, 4)
                            .background(type.getMLEntry()?.urlLength.getColor() ?? .blue)
                            .clipShape(Capsule())
                    }.width(min: 72, ideal: 72)
                } rows: {
                    ForEach(vm.tableContent) { data in
                        TableRow(data)
                    }
                }
            }.frame(minWidth: 64)
        }.navigationTitle("Queue Processor")
            .fileExporter(
                isPresented: $vm.CSVExportIsPresented,
                document: vm.resultingDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "PhishList") {_ in}
            .fileExporter(
                isPresented: $vm.RAWExportIsPresented,
                document: vm.RAWResultingDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "PhishList") {_ in}
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack {
                        if vm.bussy {
                            Button {
                                //                            vm.sendRequestQuerry()
                            } label: {
                                Image(systemName: "stop.fill")
                                    .padding(.horizontal, 8)
                            }
                            .help("Stop Execution")
                            .keyboardShortcut(".")
                        }
                        Button {
                            withAnimation {
                                vm.sendRequestQuerry()
                            }
                        } label: {
                            Image(systemName: "play.fill")
                                .padding(.horizontal, 8)
                        }
                        .disabled(vm.bussy)
                        .help("Execute Querry")
                        .keyboardShortcut(.return)
                        HStack {
                            if vm.bussy {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(
                                        CGSize(width: 0.5, height: 0.5))
                                    .frame(width: 17, height: 17)
                            } else {
                                Image(systemName: vm.statusIconName)
                            }
                            Text(vm.statusText)
                        }
                        .padding(4)
                        .padding(.trailing, 4)
                        .padding(.horizontal, 8)
                        .background(Color(
                            nsColor: NSColor.lightGray.withAlphaComponent(0.1)))
                        .clipShape(Capsule())
                    }.padding(.trailing, 8)
                }
                if vm.linesWithErrors > 0 || vm.linesWithWarnings > 0 {
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            if vm.linesWithErrors > 0 {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(vm.linesWithErrors.description).offset(CGSize(width: -4, height: 0))
                            }
                            if vm.linesWithWarnings > 0 {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Text(vm.linesWithWarnings.description).offset(CGSize(width: -4, height: 0))
                            }
                        }.padding(4)
                            .padding(.horizontal, 8)
                            .background(Color(
                                nsColor: NSColor.lightGray.withAlphaComponent(0.1)))
                            .clipShape(Capsule())
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Export ML Data") {
                            vm.exportCSV()
                        }
                        Button("Export RAW ML Data") {
                            vm.exportCSVRAW()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .padding(.horizontal, 8)
                    }
                    .disabled(!vm.readyForExport)
                    .help("Export as CSV")
                }
            }.onChange(of: sortingTable) { sort in
                vm.tableContent.sort(using: sort)
            }
    }
}

#Preview {
    MultiRequestView()
        .frame(minWidth: 1000, minHeight: 600)
    
}
