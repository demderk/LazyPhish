//
//  WhoisModule2.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.11.2024.
//

import Foundation
import NIO
import OSLog

struct WhoisRecievedDate {
    var day: Int?
    var year: Int?

    var monthText: String?

    var date: Date? {
        var monthInt: Int?
        let allMonthText: [String: Int] = [
             "january": 1,
             "february": 2,
             "march": 3,
             "april": 4,
             "may": 5,
             "june": 6,
             "july": 7,
             "august": 8,
             "september": 9,
             "october": 10,
             "november": 11,
             "december": 12
        ]
        let allMonthTextShort: [String: Int] = [
             "jan": 1,
             "feb": 2,
             "mar": 3,
             "apr": 4,
             "may": 5,
             "jun": 6,
             "jul": 7,
             "aug": 8,
             "sep": 9,
             "oct": 10,
             "nov": 11,
             "dec": 12
        ]

        guard let monthText = self.monthText else {
            return nil
        }

        if let mInt = allMonthText[monthText] {
            monthInt = mInt
        } else if let mInt = allMonthTextShort[monthText] {
            monthInt = mInt
        } else if let mInt = Int(monthText) {
            monthInt = mInt
        }
        guard let year = self.year, let monthInt = monthInt, let day = day else {
            return nil
        }

        let dateString = "\(year)-\(monthInt)-\(day)T0:0:0Z"
        if let date = try? Date(dateString, strategy: .iso8601) {
            return date
        } else { return nil }
    }

    static func fromDictionary(dictionary: [String: String?]) -> WhoisRecievedDate? {
        var day, year: Int?
        var monthText: String?
        for item in dictionary.keys {
            switch item {
            case "month", "monthText", "monthTextShort":
                if let ditem = dictionary[item], let val = ditem {
                    monthText = val
                }
            case "day":
                if let ditem = dictionary[item], let val = ditem {
                    day = Int(val)
                }
            case "year":
                if let ditem = dictionary[item], let val = ditem {
                    year = Int(val)
                }
            default:
                continue
            }
        }
        if let day = day, let year = year, let monthText = monthText {
            return WhoisRecievedDate(day: day, year: year, monthText: monthText)
        } else { return nil }
    }
}

struct WhoisData {
    var date: Date?
    var host: String
    var blinded: Bool
    var raw: String
}

enum WhoisModuleError: RequestError {
    case emptyData
    case errorCaught
    case dateParserError
    case timeout
}

final class WhoisRequestHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    
    var promise: EventLoopPromise<String>
    var finished: Bool = false
//    func setPromise(promise: EventLoopPromise<String>) {
//        self.promise = promise
//    }
    
    init(promise: EventLoopPromise<String>) {
        self.promise = promise
        Task {
            try! await Task.sleep(for: .seconds(3))
            if !finished {
                eventTimeout()
            }
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var dataBuffer = self.unwrapInboundIn(data)
        if let returnedString = dataBuffer.getString(at: 0, length: dataBuffer.readableBytes) {
            promise.succeed(returnedString)
        } else {
            promise.fail(WhoisModuleError.emptyData)
            Logger.whoisRequestLogger.info("Request string is null. Check WhoisRequestHandler")
        }
        finished = true
        context.close(promise: nil)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print(error)
        finished = true
        promise.fail(WhoisModuleError.errorCaught)
        context.close(promise: nil)
    }
    
    func eventTimeout() {
        promise.fail(WhoisError.timeout)
        print("Timeout")
    }
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if let timeout = event as? IdleStateHandler.IdleStateEvent {
            promise.fail(WhoisModuleError.timeout)
            context.close(promise: nil)
        }
    }
}

//TODO: WHOISFOUND,

class WhoisModule: RequestModule {
    private let cacheTldWhoisServer: [String: String] = [
        "com": "whois.verisign-grs.com",
        "net": "whois.verisign-grs.com",
        "org": "whois.publicinterestregistry.org",
        "cn": "whois.cnnic.cn",
        "ai": "whois.nic.ai",
        "co": "whois.nic.co",
        "ca": "whois.cira.ca",
        "do": "whois.nic.do",
        "gl": "whois.nic.gl",
        "in": "whois.registry.in",
        "io": "whois.nic.io",
        "it": "whois.nic.it",
        "me": "whois.nic.me",
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
        "ac.uk": "whois.ac.uk",
        "cz": "whois.nic.cz",
        "edu": "whois.educause.edu",
        "fr": "whois.nic.fr",
        "nl": "whois.domain-registry.nl",
        "tv": "whois.nic.tv",
        "cc": "ccwhois.verisign-grs.com",
        "br": "whois.registro.br",
        "la": "whois.nic.la",
        "ly": "whois.nic.ly",
        "be": "whois.dns.be",
        // blinded
        "de": "blinded",
        "eu": "blinded",
        "es": "blinded",
        "au": "blinded",
        "mil": "blinded",
        "gov.cn": "blinded",
        "ae": "blinded",
        "sa": "blinded",
        "ro": "blinded",
        "vn": "blinded",
        "ir": "blinded",
        "gr": "blinded",
        "za": "blinded",
        "bz": "blinded",
        "pe": "blinded",
        "az": "blinded",
        "bd": "blinded",
        "li": "blinded",
        "lv": "blinded"
        
    ]
    // swiftlint:disable line_length
    private var dateRegexParsers: [NSRegularExpression] = [
        try! NSRegularExpression(pattern: #"registered\son:\s(?<day>\d{1,2})-(?<monthTextShort>\w{3})-(?<year>\d{4})"#),
        try! NSRegularExpression(pattern: #"entry created:\n\t\w+\s(?<day>\d{1,2})(th)\s(?<monthText>\w+)\s(?<year>\d{1,4})"#),
        try! NSRegularExpression(pattern: #"\[登録年月日\]\s+(?<year>\d{1,4})\/(?<month>\d{1,2})\/(?<day>\d{1,2})"#),
        try! NSRegularExpression(pattern: #"\[登録年月日\]\s+(?<year>\d{1,4})\/(?<month>\d{1,2})\/(?<day>\d{1,2})"#),
        try! NSRegularExpression(pattern: #"created:\s+(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})"#),
        try! NSRegularExpression(pattern: #"created:\s+(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})"#),
        try! NSRegularExpression(pattern: #"creation date:\s+(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})"#),
        try! NSRegularExpression(pattern: #"registered:\s+(\w{3})\s(?<monthTextShort>\w{3})\s(?<day>\d{2})\s(?<year>\d{4})"#),
        try! NSRegularExpression(pattern: #"created:\s+(?<day>\d{2}).(?<month>\d{2}).(?<year>\d{4})"#),
        try! NSRegularExpression(pattern: #"registration time:\s+(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})"#),
        try! NSRegularExpression(pattern: #"domain record activated:\s+(?<day>\d{2})-(?<monthTextShort>\w{3})-(?<year>\d{4})"#),
        try! NSRegularExpression(pattern: #"등록일\s+:\s+(?<year>\d{4}).\s(?<month>\d{2}).\s(?<day>\d{2})"#),
        try! NSRegularExpression(pattern: #"created:\s+(?<year>\d{4}).(?<month>\d{2}).(?<day>\d{2})"#),
        try! NSRegularExpression(pattern: #"record created on\s+(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})"#),
        try! NSRegularExpression(pattern: #"registered:\s+(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})"#),
        try! NSRegularExpression(pattern: #"created date:\s+(?<day>\d{1,2})\s(?<monthTextShort>\w{3})\s(?<year>\d{4})"#)
    ]
    // swiftlint:enable line_length
    
    private var referRegexParser: NSRegularExpression = try! NSRegularExpression(pattern: #"refer:\s*(?<refer>[\w1-9.-]+)$"#)
    
    private let port = 43
    private static var threadedGroup: MultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var clientBootstrap: ClientBootstrap = ClientBootstrap(group: threadedGroup)
    
    var dependences: DependencyCollection = DependencyCollection()
    var status: ModuleStatus = .planned
    var whoisData: WhoisData?
    var blinded: Bool { whoisData?.blinded ?? false }
    var whoisFound: Bool { status.justCompleted }
    var date: Date? { whoisData?.date }
    var dateText: String {
        if blinded {
            return "Domain zone is blinded"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        var text = "Creation data failed"
        dateFormatter.locale = Locale(identifier: "en_US")
        if let date = self.date {
            text = dateFormatter.string(from: date)
        }
        return text
    }
    
    private func getRawRange(raw: String) -> NSRange {
        return NSRange(raw.startIndex..<raw.endIndex, in: raw)
    }
    
    func processDate(rawWhois: String) -> Date? {
        let raw = rawWhois.lowercased()
        for regex in dateRegexParsers {
            guard let match = regex.matches(in: raw, range: getRawRange(raw: raw)).first else {
                continue
            }
            
            var parsedData: [String: String?] = [
                "month": nil,
                "day": nil,
                "year": nil,
                "monthText": nil,
                "monthTextShort": nil
            ]
            
            for key in parsedData.keys {
                let matchRange = match.range(withName: key)
                
                if let substringRange = Range(matchRange, in: raw) {
                    let capture = String(raw[substringRange])
                    parsedData[key] = capture
                }
            }
            
            return WhoisRecievedDate.fromDictionary(dictionary: parsedData)?.date
        }
        return nil
    }
    
    func getRefer(raw: String) -> String? {
        guard let match = referRegexParser.matches(in: raw, range: getRawRange(raw: raw)).first else {
            return nil
        }
        
        let range = match.range(withName: "refer")
        if let substringRange = Range(range, in: raw) {
            return String(raw[substringRange])
        }
        return nil
    }
    
    private func getCachedWhoisServer(for domain: String) -> String? {
        var tld: String = ""
        let toFind = Array(domain.components(separatedBy: ".").reversed())
        if StrictURL.isTwoSLD(host: domain) {
            tld = "\(toFind[1]).\(toFind[0])"
            if let server = cacheTldWhoisServer[tld] {
                return server
            }
        }
        tld = domain.components(separatedBy: ".").last ?? ""
        return cacheTldWhoisServer[tld]
    }
    
    func processWhoisRequest(server: String, host: String) -> EventLoopFuture<String> {
        clientBootstrap.connect(host: server, port: self.port).flatMap({ channel in
            let promise = channel.eventLoop.makePromise(of: String.self)
            
            _ = channel.pipeline.addHandlers([
                IdleStateHandler(allTimeout: .seconds(3)),
                WhoisRequestHandler(promise: promise)])
            
            var buffer = channel.allocator.buffer(capacity: host.utf16.count + 8)
            buffer.writeString("\(host)\r\n")
            _ = channel.writeAndFlush(buffer)
            
            return promise.futureResult
        })
    }
    
    func lookup(host: String, server: String, delay: Double = 0.3) async throws -> String {
        let response = try await processWhoisRequest(server: server, host: host).get()
        
        if let refer = getRefer(raw: response) {
            try! await Task.sleep(for: .seconds(delay))
            return try await lookup(host: host, server: refer)
        } else {
            return response
        }
    }
    
    func shutdownThreads() {
//        try? threadedGroup!.syncShutdownGracefully()
    }
    
    func execute(remote: RequestInfo) async {
        status = .executing
        let server = getCachedWhoisServer(for: remote.host) ?? "whois.iana.org"
        guard server != "blinded" else {
//            print("response blinded. skiping...")
            whoisData = WhoisData(date: nil,
                                  host: remote.host,
                                  blinded: true,
                                  raw: "")
            status = .completed
            return
        }
        do {
            let response = try await lookup(host: remote.host, server: server)
            whoisData = WhoisData(date: processDate(rawWhois: response),
                                  host: remote.host,
                                  blinded: false,
                                  raw: response)
            status = .completed
//            print("response succeed")
        } catch let error as RequestError {
            status = .failed(error: error)
            return
        } catch {
            status = .failed(error: WhoisError.unknown(error))
            print("UNKNOWN ERR: \(error)")
            return
        }
        if whoisData?.date != nil {
            status = .completed
        } else {
            status = .completedWithErrors(errors: [WhoisModuleError.dateParserError])
        }
    }
    
    deinit {
//        print("deinit")
//            try? group.syncShutdownGracefully()
    }
}
