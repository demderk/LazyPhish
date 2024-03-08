//
//  MainPageVM.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 07.03.2024.
//

import Foundation

class MainPageVM : ObservableObject {
    
    @Published var urlText: String = ""
    @Published var registrationDate: String = ""
    @Published var yandexSQI: String = ""
    @Published var errorInfo: String = ""
    @Published var isYearLong: Bool = true
    
    
    private var urlInfo: URLInfo? = nil
    
    @MainActor
    func getData() {
        self.urlInfo = URLInfo(URL(string: urlText)!)
        guard let url = self.urlInfo else {
            registrationDate = "URL Parse Error"
            return
        }
        registrationDate = "Pinging..."
        url.refreshRemoteData {
            self.setAvailableData()
        } onError: { errorList in
            self.errorInfo = errorList.map { error in
                error.localizedDescription
            }.description
            self.setAvailableData()
        }
    }
    
    func setAvailableData() {
        guard let url = self.urlInfo else {
            return
        }
        if let sqi = url.yandexSQI {
            self.yandexSQI = String(sqi)
        } else {
            self.yandexSQI = "Yandex SQI Error"
        }
        self.registrationDate = url.creationDate?.formatted() ?? "Whois Date Error"
    }
}
