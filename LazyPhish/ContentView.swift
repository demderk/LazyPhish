//
//  ContentView.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 04.03.2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject var vm = MainPageVM()
    
    var body: some View {
        HStack{
            Text(vm.errorInfo)
            VStack(alignment: .center){
                Text("URL")
                HStack{
                    Spacer()
                    TextField("URL", text: $vm.urlText)
                        .frame(width: 256)
                        .onSubmit {
                            vm.getData()
                        }
                    Button("Get Info", action: vm.getData)
                    Spacer()
                }
                Text("Registration: \(vm.creationDate)")
                Text("Yandex SQI: \(vm.yandexSQI)")
                Text("OPR Grade \(vm.OPRGrade)")
                Text("OPR Rank \(vm.OPRRank)")
                
            }
        }
    }
}

#Preview {
    ContentView().frame(minWidth: 1000, minHeight: 600)
}
