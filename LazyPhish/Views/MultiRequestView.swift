//
//  MultiRequestView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.03.2024.
//

import SwiftUI

struct MultiRequestView: View {
    @ObservedObject var vm = MultiRequestVM()
    
    var body: some View {
        VStack {
            HStack {
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
                        Text(type.phishInfo.yandexSQI?.formatted() ?? "Ureachable")
                    }
                    TableColumn("OPR Rank") { type in
                        Text(type.phishInfo.OPRRank?.formatted() ?? "Ureachable")
                    }
                    TableColumn("Creation Date") { type in
                        Text(type.phishInfo.creationDate?.formatted() ?? "Ureachable")
                    }
                } rows: {
                    ForEach(vm.tableContent) { data in
                        TableRow(data)
                    }
                }
            }
            Button("Send") {
                vm.sendRequestQuerry()
            }
        }
    }
}

#Preview {
    MultiRequestView()
        .frame(minWidth: 1000, minHeight: 600)

}
