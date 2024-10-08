//
//  Server.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 14.05.2024.
//

import Foundation
import Vapor
import OSLog

enum PhishRouteAction: Int, Codable {
    case reject = 0
    case notify = 1
    case accept = 2
}

struct PhishingSite: Content {
    var host: String
    var trustIndex: Double
    var isPhishing: Bool
    var action: PhishRouteAction
}

struct PhishingInfo: Content {
    var host: String
}

class Server {
    private var app: Application?
    
    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Reflection Server"
    )
    
    private static let phishML = try! PhishML()
    
    func startServer() {
        guard app == nil else {
            return
        }
        
        app = try! Application(.detect())
        
        guard let server = app else {
            return
        }
        
        server.post("phishing") { req async throws in
            if let body = try? req.content.decode(PhishingInfo.self),
               let request = try? PhishRequestSingle(body.host),
               let mlEntry = await request.processRequest().getMLEntry() {
                
                let prediction = Server.phishML.predictPhishing(input: mlEntry)
                let response = PhishingSite(
                    host: body.host,
                    trustIndex: prediction.IsPhishingProbability[0]!,
                    isPhishing: prediction.IsPhishing == 1,
                    action: prediction.IsPhishing == 1 ? .reject : .accept
                )
                return response
            } else {
            }
            return PhishingSite(host: "-1", trustIndex: -1, isPhishing: false, action: .accept)
        }
        
        DispatchQueue.global().async {
            try! server.run()
        }
    }
    
    func stopServer() {
        guard let server = app else {
            return
        }
        server.shutdown()
    }
}
