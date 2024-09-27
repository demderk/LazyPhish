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
    public var creationDate: Date?

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

class WhoisConnection {
    private var server: String = "whois.iana.org"
    private var connection: NWConnection?

    private let cacheTldWhoisServer: [String: String] = [
        "com": "whois.verisign-grs.com",
        "net": "whois.verisign-grs.com",
        "org": "whois.publicinterestregistry.org",
        "cn": "whois.cnnic.cn",
        "ai": "whois.nic.ai",
        "au": "whois.auda.org.au",
        "co": "whois.nic.co",
        "ca": "whois.cira.ca",
        "do": "whois.nic.do",
        "gl": "whois.nic.gl",
        "in": "whois.registry.in",
        "io": "whois.nic.io",
        "it": "whois.nic.it",
        "me": "whois.nic.me",
        "ro": "whois.rotld.ro",
        "rs": "whois.rnids.rs",
        "so": "whois.nic.so",
        "us": "whois.nic.us",
        "ws": "whois.website.ws",
        "agency": "whois.nic.agency",
        "app": "whois.nic.google",
        "biz": "whois.nic.biz",
        "dev": "whois.nic.google",
        "house": "whois.nic.house",
        "info": "whois.nic.info",
        "link": "whois.uniregistry.net",
        "live": "whois.nic.live",
        "nyc": "whois.nic.nyc",
        "one": "whois.nic.one",
        "online": "whois.nic.online",
        "shop": "whois.nic.shop",
        "site": "whois.nic.site",
        "xyz": "whois.nic.xyz",
        "ru": "whois.tcinet.ru",
        "jp": "whois.jprs.jp",
        "fm": "whois.nic.fm",
        "gov": "whois.dotgov.gov",
        "uk": "whois.nic.uk",
        "cz": "whois.nic.cz",
        "edu": "whois.educause.edu",
        "de": "whois.denic.de",
        "fr": "whois.nic.fr",
        "nl": "whois.domain-registry.nl",
        "tv": "whois.nic.tv",
        "cc": "ccwhois.verisign-grs.com",
        "eu": "whois.eu",
        "br": "whois.registro.br",
        "la": "whois.nic.la",
        "ly": "whois.nic.ly",
        "be": "whois.dns.be",
        // FAILING
        "es": "whois.nic.es"
    ]

    private func getCachedWhoisServer(for domain: String) -> String? {
        let tld = domain.components(separatedBy: ".").last ?? ""
        return cacheTldWhoisServer[tld]
    }

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
            content: Data("\(host)\r\n".utf8),
            completion: .idempotent)
        let response: String = try await withCheckedThrowingContinuation { continuation in
            establishedConnection.receiveMessage { content, _, _, error in
                if let failed = error {
                    continuation.resume(throwing: failed)
                    return
                }
                guard let recievedData = content else {
                    continuation.resume(throwing: WhoisError.responseIsNil)
                    return
                }
                let stringResponse = String(decoding: recievedData, as: UTF8.self)
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
        if let cached = getCachedWhoisServer(for: host) {
            server = cached
        }
        let hostComponents = Array(host.components(separatedBy: ".").reversed())
        guard hostComponents.count > 1 else {
            throw WhoisError.badRequest(description: "Host is incorrect. Hostname: \(host)")
        }

        let parent = "\(hostComponents[1]).\(hostComponents[0])"
        let response = try await makeRequest(host: parent)
        let responseArray = buildResponseArray(responseText: response)
        if let refer = responseArray.first(where: { $0.key == "refer" }) {
            server = refer.value
            try await Task.sleep(for: .seconds(0.1))
            return try await makeRecursiveRequest(host: parent)
        } else {
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
                if whoisData.creationDate == nil { whoisData.creationDate = try? getDate(value) }
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

    func lookup(host: String, timeout: Int = 3000) async throws -> WhoisInfo {
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
        switch await recursiveTask.result {
        case .success(let response):
            return parseWhoisResponse(response)
        case .failure(let x):
            throw x
        }

    }

    private func getDate(_ whoisDate: String) throws -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd-MMM-yyyy"
        var res = dateFormatter.date(from: whoisDate)
        if res == nil {
            res = try? Date(whoisDate, strategy: .iso8601)
        }
        guard let result = res else {
            throw WhoisError.dateFormatError
        }
        return result
    }

    deinit {
        if connection?.state == .cancelled {
            connection?.cancel()
        }
    }
}
