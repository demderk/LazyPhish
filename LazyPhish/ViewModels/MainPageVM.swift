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
        
    private var urlInfo: PhishRequestBase? = nil
    
    init() {

    }
    
    @MainActor
    func getData() {
        errorInfo = ""
        self.urlInfo = PhishRequestBase(URL(string: urlText)!)
        guard let url = self.urlInfo else {
            creationDate = "URL Parse Error"
            return
        }
        
        creationDate = "Pinging..."
        setupSubscriptions()
        url.refreshRemoteData {
            self.setAvailableData()
        } onError: { _ in
            
        }
//        } onError: { errorList in
//            self.errorInfo = errorList.map { error in
//                error.localizedDescription
//            }.joined(separator: "\n")
////            self.setAvailableData()
//        }
    }
    
    func setupSubscriptions() {
        
        guard let url = urlInfo else { return }
//        
//        url.$creationDate.sink {
//            if let date = $0 {
//                self.creationDate = date.formatted()
//            }
//        }.store(in: &url.publicSubscriptions)
//        
//        url.$OPRRank.sink {
//            if let rank = $0 {
//                self.OPRRank = rank.description
//            }
//        }.store(in: &url.publicSubscriptions)
//        
//        url.$OPRGrade.sink {
//            if let grade = $0 {
//                self.OPRGrade = grade.description
//            }
//        }.store(in: &url.publicSubscriptions)
//        
//        url.$yandexSQI.sink {
//            if let sqi = $0 {
//                self.yandexSQI = sqi.description
//            }
//        }.store(in: &url.publicSubscriptions)
    }
    
    func setAvailableData() {
        guard let url = self.urlInfo else {
            return
        }
        self.OPRGrade = (url.phishInfo.OPRGrade ?? -1).description
        self.yandexSQI = (url.phishInfo.yandexSQI ?? -1).description
        self.creationDate = (url.phishInfo.creationDate ?? Date(timeIntervalSince1970: 0)).formatted()
        self.OPRRank = (url.phishInfo.OPRRank ?? -1).description
        
    }
}
