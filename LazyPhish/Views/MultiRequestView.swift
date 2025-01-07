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
                Table(of: VisualPhishingEntry.self) {
                    TableColumn("ID") { item in
                        Text(item.id.description)
                    }
                    TableColumn("URL") { item in
                        Text(item.url)
                    }
                    TableColumn("Creation Date") { item in
                        Text(item.date)
                    }
                    TableColumn("OPR") { item in
                        Text(item.opr)
                    }
                    TableColumn("SQI") { item in
                        Text(item.sqi)
                    }
                    TableColumn("Is IP") { item in
                        Text(item.isIP)
                    }
                    TableColumn("Subdomains") { item in
                        Text(item.subDomains)
                    }
                    TableColumn("Prefixes") { item in
                        Text(item.prefixCount)
                    }
                    TableColumn("Length") { item in
                        Text(item.length)
                    }
                    TableColumn("Host Length") { item in
                        Text(item.hostLength)
                    }

                } rows: {
                    ForEach(vm.tableContent) { data in
                        TableRow(data.visual)
                    }
                }
            }.frame(minWidth: 64)
        }.navigationTitle("Queue Processor")
            .fileExporter(
                isPresented: $vm.educationalExportIsPresented,
                document: vm.educationalFile,
                contentType: .commaSeparatedText,
                defaultFilename: "PhishList") {_ in}
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack {
                        Button {
                            if !vm.busy {
                                vm.revise()
                            }
                        } label: {
                            Image(systemName: "bandage.fill")
                                .padding(.horizontal, 8)
                                .frame(width: 48)
                        }
                        .disabled(!vm.reviseable || vm.busy)
                        .help("Revise Querry")
                        Button {
                            if !vm.busy {
                                vm.start()
                            } else {
                                vm.stop()
                            }
                        } label: {
                            Image(systemName: vm.busy ? "stop.fill" : "play.fill")
                                .padding(.horizontal, 8)
                                .frame(width: 48)
                        }
                        .help(vm.busy ? "Cancel Execution" : "Execute Querry")
                        .keyboardShortcut(.return)
                        StatusView(busy: $vm.busy,
                                   iconName: $vm.statusIconName,
                                   status: $vm.statusText)
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
                        Button("Export RAW ML Data") {
//                            vm.exportCSVRAW()
                        }
                        Button("Export Results") {
                            vm.exportEducationalFile()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .padding(.horizontal, 8)
                    }
                    .disabled(!vm.readyForExport)
                    .help("Export as CSV")
                }
            }
    }
}

#Preview {
    MultiRequestView()
        .frame(minWidth: 1000, minHeight: 600)

}
