//
//  ServerVM.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 14.05.2024.
//

import Foundation
import Vapor

class ServerVM : ObservableObject {
    let server = Server()
    
    func createServer() {
        server.startServer()
    }
    
    func stop() {
        server.stopServer()
    }
}
