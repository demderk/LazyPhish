//
//  WhoisModule2.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 17.11.2024.
//

import Foundation
import NIO
import OSLog

// TODO: WHOISFOUND,
// Вот что это, Рома, блин. Что это значит? Что я хотел? Пишем нормальный код, бредик не пишем.
// ** Наверно я тут не определяю найден ли Whois или он вернул ошибку **

// Нужно удалить синглтоны, потому что если у нас будет 2 окна, все может пойти не по плану

class WhoisModule: RequestModule {
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
    
    private var referRegexParser: NSRegularExpression = try! NSRegularExpression(pattern: #"refer:\s*(?<refer>[\w1-9.-]+)(\n|\r)"#)
    
    private let port = 43
    private var clientBootstrap: ClientBootstrap = ClientBootstrap(group: threadedGroup)
    
    private static var threadedGroup: MultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private static var serverConductor = WhoisServerConductor()
    private static var addressCache = WhoisCache()
    
    var dependences: DependencyCollection = DependencyCollection()
    var status: RemoteJobStatus = .planned
    var whoisData: WhoisData?
    var blinded: Bool { whoisData?.blinded ?? false }
    var whoisFound: Bool { status.isFinished }
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
     
    
    func processWhoisRequest(server: String, host: String) async -> EventLoopFuture<String> {
        await WhoisModule.serverConductor.serverWait(server)
        return clientBootstrap.connect(host: server, port: self.port).flatMap({ channel in
            
            let promise = channel.eventLoop.makePromise(of: String.self)
            
            _ = channel.pipeline.addHandlers([
                IdleStateHandler(allTimeout: .seconds(3)),
                WhoisRequestHandler(promise: promise)])
            
            var buffer = channel.allocator.buffer(capacity: host.utf16.count + 8)
            buffer.writeString("\(host)\r\n")
            _ = channel.writeAndFlush(buffer)
            
            return promise.futureResult.always({ _ in
                Task {
                    await WhoisModule.serverConductor.serverSignal(server)
                }
            })
        })
    }

    func lookup(host: String, server: String) async throws -> String {
        let response = try await processWhoisRequest(server: server, host: host).get()
                
        if let refer = getRefer(raw: response) {
            return try await lookup(host: host, server: refer)
        } else {
            WhoisModule.addressCache.push(host: host, server: server)
            return response
        }
    }
    
    func execute(remote: RemoteRequest) async {
        status = .executing
        let server = WhoisModule.addressCache.pull(remote.host)
        guard !server.isBlinded else {
            whoisData = WhoisData(date: nil,
                                  host: remote.host,
                                  blinded: true,
                                  raw: "")
            status = .completed
            return
        }
        do {
            let response = try await lookup(host: remote.host, server: server.server)
            whoisData = WhoisData(date: processDate(rawWhois: response),
                                  host: remote.host,
                                  blinded: false,
                                  raw: response)
            status = .completed
        } catch let error as WhoisModuleError {
            status = .failed(error)
            
            switch error {
            case .NIOInternal(let error):
                print("OWNER \(remote.host) : \(error)")
            default:
                break
            }
            return
        } catch {
            status = .failed(WhoisModuleError.unknown(error))
            print("UNKNOWN ERR: \(error)")
            return
        }
        if whoisData?.date != nil {
            status = .completed
        } else {
            status = .completedWithErrors([WhoisModuleError.dateParserError])
        }
    }
    
    deinit {
//        print("deinit")
//            try? group.syncShutdownGracefully()
    }
}
