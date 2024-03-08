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
    @Published var OPRRank: String = ""
    @Published var OPRGrade: String = ""
    
    
    private var urlInfo: URLInfo? = nil
    
    @MainActor
    func getData() {
        errorInfo = ""
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
            }.joined(separator: "\n")
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
        if let rank = url.OPRRank {
            self.OPRRank = String(rank)
        } else {
            self.OPRRank = "OPR RANK Error"
        }
        if let grade = url.OPRGrade {
            self.OPRGrade = grade.description
        } else {
            self.OPRGrade = "OPR GRADE Error"
        }

    }
}
