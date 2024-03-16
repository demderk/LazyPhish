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
        
    private var urlInfo: PhishRequest? = nil
    
    init() {

    }
    
    @MainActor
    func getData() {
        errorInfo = ""
        self.urlInfo = PhishRequest(URL(string: urlText)!)
        guard let url = self.urlInfo else {
            creationDate = "URL Parse Error"
            return
        }
        
        creationDate = "Pinging..."
        url.refreshRemoteData {
            self.setAvailableData()
        } onError: { _ in
            
        }
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
