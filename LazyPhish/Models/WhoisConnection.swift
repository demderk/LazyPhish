//
//  WhoisConnection.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 05.06.2024.
//  Based on https://github.com/isaced/SwiftWhois by isaced
//

import Foundation
import Network
import os

struct WhoisInfo {
    /// The domain name, e.g. example.com
    public var domainName: String?
    
    /// The registrar
    public var registrar: String?
    
    /// The registrar Whois server
    public var registrarWhoisServer: String?
    
    /// The registrant contact email
    public var registrantContactEmail: String?
    
    /// The registrant
    public var registrant: String?
    
    /// The creation date
    public var creationDate: String?
    
    /// The expiration date
    public var expirationDate: String?
    
    /// The last updated date
    public var updateDate: String?
    
    /// The name servers, e.g. ns1.google.com
    public var nameServers: [String]?
    
    /// The domain status, e.g. clientTransferProhibited
    public var domainStatus: [String]?
    
    /// The raw Whois data
    public var rawData: String?
}

extension Logger {
    public static var subsystem = Bundle.main.bundleIdentifier!
    
    public static var whoisLogger = Logger(
        subsystem: subsystem,
        category: "whoisRequest")
}

enum WhoisConnectionError: Error {
    case responseIsNil
    case badResponse
    case timeout
}

class WhoisConnection {
    private var server: String = "whois.iana.org"
    private var connection: NWConnection?
    
    @discardableResult
    func establishConnection() -> NWConnection {
        let newConnection = NWConnection.init(
            to: NWEndpoint.hostPort(
                host: NWEndpoint.Host(server),
                port: 43),
            using: .tcp)
        self.connection = newConnection
        return newConnection
    }
    
    func makeRequest(host: String) async throws -> String {
        let establishedConnection = connection ?? establishConnection()
        establishedConnection.start(queue: .global())
        establishedConnection.send(
            content: "\(host)\r\n".data(using: .utf8),
            completion: .idempotent)
        let response: String = try await withCheckedThrowingContinuation { continuation in
            establishedConnection.receiveMessage { content, _, _, error in
                if let failed = error {
                    continuation.resume(throwing: failed)
                    return
                }
                guard let recievedData = content else {
                    continuation.resume(throwing: WhoisConnectionError.responseIsNil)
                    return
                }
                guard let stringResponse = String(data: recievedData, encoding: .utf8) else {
                    continuation.resume(throwing: WhoisConnectionError.badResponse)
                    return
                }
                continuation.resume(returning: stringResponse)
            }
        }
        connection?.cancel()
        connection = nil
        return response
    }
    
    func buildResponseArray(responseText: String) -> [(key: String, value: String)] {
        var result: [(String, String)] = []
        let lines = responseText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n")
        for item in lines {
            let pair = item
                .split(separator: ":", maxSplits: 1)
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            guard pair.count == 2 else {
                continue
            }
            result.append((pair[0], pair[1]))
        }
        return result
    }
    
    func makeRecursiveRequest(host: String) async throws -> String {
        //        try await Task.sleep(for: .seconds(0.4))
        let response = try await makeRequest(host: host)
        let responseArray = buildResponseArray(responseText: response)
        if let refer = responseArray.first(where: { $0.key == "refer" }) {
            server = refer.value
            try await Task.sleep(for: .seconds(0.4))
            return try await makeRecursiveRequest(host: host)
        }
        else {
            return response
        }
    }
    
    func parseWhoisResponse(_ response: String) -> WhoisInfo {
        var whoisData = WhoisInfo()
        let standardizedResponse = response.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = standardizedResponse.split(separator: "\n")
        for line in lines {
            let parts = line
                .split(separator: ":", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count == 2 else { continue }
            
            let key = parts[0].lowercased()
            let value = parts[1]
            
            switch key {
            case "domain name":
                if whoisData.domainName == nil { whoisData.domainName = value }
            case "registrant":
                if whoisData.registrant == nil { whoisData.registrant = value }
            case "registrant contact email", "registrant email":
                if whoisData.registrantContactEmail == nil { whoisData.registrantContactEmail = value }
            case "registrar whois server":
                if whoisData.registrarWhoisServer == nil { whoisData.registrarWhoisServer = value }
            case "registrar", "sponsoring registrar":
                if whoisData.registrar == nil { whoisData.registrar = value }
            case "creation date",
                "created",
                "registration time", 
                "登録年月日",
                "domain record activated":
                if whoisData.creationDate == nil { whoisData.creationDate = value }
            case "expiration date",
                "expires on",
                "registry expiry date",
                "registrar registration expiration date",
                "expiration time":
                if whoisData.expirationDate == nil { whoisData.expirationDate = value }
            case "updated date", "last updated":
                if whoisData.updateDate == nil { whoisData.updateDate = value }
            case "name server":
                var nameServers = whoisData.nameServers ?? []
                nameServers.append(value.lowercased())
                whoisData.nameServers = nameServers
            case "domain status":
                var domainStatus = whoisData.domainStatus ?? []
                
                // "clientDeleteProhibited https://icann.org/epp#clientDeleteProhibited"
                if let status = value.split(separator: " ").first, !status.isEmpty {
                    domainStatus.append(String(status))
                }
                
                whoisData.domainStatus = domainStatus
            default:
                break
            }
        }
        whoisData.rawData = response
        return whoisData
    }
    
    func lookup(host: String, timeout: Int = 2000) async throws -> WhoisInfo {
        let recursiveTask = Task {
            return try await makeRecursiveRequest(host: host)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeout)) { [self] in
            if !recursiveTask.isCancelled {
                connection?.cancel()
                connection = nil
                recursiveTask.cancel()
            }
        }
        let response = try await recursiveTask.value
        switch await recursiveTask.result {
        case .success(let string):
            return parseWhoisResponse(response)
        case .failure(let x):
            throw x
        }
        
    }
    
    deinit {
        if connection?.state == .cancelled {
            connection?.cancel()
        }
    }
}
