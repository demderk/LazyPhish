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
        
    var body: some View {
        VStack {
            HSplitView {
                TextEditor(text: $vm.requestText)
                    .font(.body)
                Table(of: PhishTableEntry.self) {
                    TableColumn("ID") { type in
                        Text(type.id.formatted())
                    }
                    TableColumn("Url") { type in
                        Text(type.phishInfo.url.formatted())
                    }
                    TableColumn("yandexSQI") { type in
                        VStack {
                            Text(type.phishInfo.yandexSQI?.formatted() ??
                                 (type.phishInfo.remote.yandexSQI.error?.localizedDescription ??
                                  "Ureachable"))
                            .padding(.horizontal, 4)
                            .background(type.phishInfo.getMLEntry()?.yandexSQI.getColor() ?? .blue)
                            .clipShape(Capsule())
                            
                        }
                    }
                    TableColumn("OPR Rank") { type in
                        Text(type.phishInfo.OPR?.rank?.description ??
                             (type.phishInfo.remote.OPR.error?.localizedDescription ??
                              "Ureachable"))
                        .padding(.horizontal, 4)
                        .background(type.phishInfo.getMLEntry()?.OPR.getColor() ?? .blue)
                        .clipShape(Capsule())
                    }
                    TableColumn("Creation Date") { type in
                        Text(type.phishInfo.creationDate?.formatted() ??
                             (type.phishInfo.remote.whois.error?.localizedDescription ??
                              "Ureachable"))
                        .padding(.horizontal, 4)
                        .background(type.phishInfo.getMLEntry()?.creationDate.getColor() ?? .blue)
                        .clipShape(Capsule())
                    }
                    TableColumn("Have Whois") { type in
                        Text(type.phishInfo.whois != nil ? "Yes" : "No")
                            .padding(.horizontal, 4)
                            .background(type.phishInfo.getMLEntry()?.haveWhois.getColor() ?? .blue)
                            .clipShape(Capsule())
                    }
                    TableColumn("Is IP") { type in
                        Text(type.phishInfo.isIP ? "Yes" : "No")
                            .padding(.horizontal, 4)
                            .background(type.phishInfo.getMLEntry()?.isIP.getColor() ?? .blue)
                            .clipShape(Capsule())

                    }
                    TableColumn("Prefixes") { type in
                        Text(type.phishInfo.prefixCount.description)
                            .padding(.horizontal, 4)
                            .background(type.phishInfo.getMLEntry()?.prefixCount.getColor() ?? .blue)
                            .clipShape(Capsule())
                    }
                    TableColumn("Subdomains") { type in
                        Text(type.phishInfo.subDomainCount.description)
                            .padding(.horizontal, 4)
                            .background(type.phishInfo.getMLEntry()?.subDomainCount.getColor() ?? .blue)
                            .clipShape(Capsule())
                    }
                    TableColumn("URL Length") { type in
                        Text(type.phishInfo.urlLength.description)
                            .padding(.horizontal, 4)
                            .background(type.phishInfo.getMLEntry()?.urlLength.getColor() ?? .blue)
                            .clipShape(Capsule())
                    }
                } rows: {
                    ForEach(vm.tableContent) { data in
                        TableRow(data)
                    }
                }
            }
        }.navigationTitle("Request Querry")
            .fileExporter(isPresented: $vm.CSVExportIsPresented, document: vm.resultingDocument, contentType: .commaSeparatedText, defaultFilename: "PhishList") { r in
                print(r)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                        Button {
                            vm.sendRequestQuerry()
                        } label: {
                            Image(systemName: "play.fill")
                                .padding(.horizontal, 16)
                        }.padding(.trailing, 8)
                        .disabled(vm.bussy)
                        .help("Execute Querry")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Export ML Data") {
                            vm.exportCSV()
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
