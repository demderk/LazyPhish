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
                Table(of: PhishTableEntry.self) {
                    TableColumn("ID") { item in
                        Text(item.id.description)
                    }
                    TableColumn("Host") { item in
                        Text(item.host)
                    }
                    TableColumn("Creation Date") { item in
                        Text(item.date ?? "Date Error")
                    }
                    TableColumn("OPR") { item in
                        Text(item.opr?.description ?? "OPR Error")
                    }
                    TableColumn("SQI") { item in
                        Text(item.sqi?.description ?? "SQI Error")
                    }
                    TableColumn("Is IP") { item in
                        Text(item.isIP?.description ?? "Regex Error")
                    }
                    TableColumn("Subdomains") { item in
                        Text(item.subDomains?.description ?? "Regex Error")
                    }
                    TableColumn("Prefixes") { item in
                        Text(item.prefixCount?.description ?? "Regex Error")
                    }
                    TableColumn("Length") { item in
                        Text(item.length?.description ?? "Regex Error")
                    }
                    
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
                        if vm.busy {
                            Button {
                                vm.cancel()
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
                        .disabled(vm.busy)
                        .help("Execute Querry")
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
            }
    }
}

#Preview {
    MultiRequestView()
        .frame(minWidth: 1000, minHeight: 600)

}
