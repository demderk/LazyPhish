//
//  MainPageVM.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 07.03.2024.
//

import Foundation
import Combine

class MainPageVM : ObservableObject {
    
    
    
    @Published var urlText: String = ""
    @Published var creationDate: String = ""
    @Published var yandexSQI: String = ""
    @Published var errorInfo: String = ""
    @Published var isYearLong: Bool = true
    @Published var OPRRank: String = ""
    @Published var OPRGrade: String = ""
        
    private var urlInfo: URLInfo? = nil
    
    init() {

    }
    
    @MainActor
    func getData() {
        errorInfo = ""
        self.urlInfo = URLInfo(URL(string: urlText)!)
        guard let url = self.urlInfo else {
            creationDate = "URL Parse Error"
            return
        }
        
        creationDate = "Pinging..."
        setupSubscriptions()
        url.refreshRemoteData {
//            self.setAvailableData()
        } onError: { errorList in
            self.errorInfo = errorList.map { error in
                error.localizedDescription
            }.joined(separator: "\n")
//            self.setAvailableData()
        }
    }
    
    func setupSubscriptions() {
        
        guard let url = urlInfo else { return }
        
        url.$creationDate.sink {
            if let date = $0 {
                self.creationDate = date.formatted()
            }
        }.store(in: &url.publicSubscriptions)
        
        url.$OPRRank.sink {
            if let rank = $0 {
                self.OPRRank = rank.description
            }
        }.store(in: &url.publicSubscriptions)
        
        url.$OPRGrade.sink {
            if let grade = $0 {
                self.OPRGrade = grade.description
            }
        }.store(in: &url.publicSubscriptions)
        
        url.$yandexSQI.sink {
            if let sqi = $0 {
                self.yandexSQI = sqi.description
            }
        }.store(in: &url.publicSubscriptions)
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
        self.creationDate = url.creationDate?.formatted() ?? "Whois Date Error"
        if let rank = url.OPRRank {
            self.OPRRank = rank.description
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
