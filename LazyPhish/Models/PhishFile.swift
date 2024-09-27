//
//  File.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 26.04.2024.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CodableCSV

struct PhishFile: FileDocument {
    static var readableContentTypes: [UTType] = [.commaSeparatedText]

    private var entries: [MLEntry] = []

    init(_ entries: [MLEntry]) {
        self.entries.append(contentsOf: entries)
    }

    init(configuration: ReadConfiguration) throws {

    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard !entries.isEmpty else {
            throw FileError.nothingToExport
        }
        let encoder = CSVEncoder { $0.headers = MLEntry.getHeaders() }
        let encodedData = try encoder.encode(entries)
        return FileWrapper(regularFileWithContents: encodedData)
    }
}
struct RawPhishInfo: Codable {
    var isIP: Int
    var haveWhois: Int
    var creationDate: Double
    var OPRRank: Int
    var OPRGrade: Decimal
//    var urlLength: Int
    var prefixCount: Int
    var subDomainCount: Int
}

extension RawPhishInfo {
    init(_ info: PhishInfo) {
        isIP = info.isIP ? 1 : 0
        creationDate = info.creationDate?.timeIntervalSince1970 ?? -1.0
        haveWhois = info.whois == nil ? 0 : 1
        OPRRank = info.OPRRank ?? -1
        OPRGrade = info.OPRGrade ?? -1
//        urlLength = info.urlLength
        prefixCount = info.prefixCount
        subDomainCount = info.subDomainCount
    }

    static func getHeaders() -> [String] {
        ["isIP",
         "haveWhois",
         "creationDate",
         "OPRRank",
         "OPRGrade",
         "prefixCount",
         "subDomainCount"]
    }
}

struct RawPhishFile: FileDocument {
    static var readableContentTypes: [UTType] = [.commaSeparatedText]

    private var entries: [PhishInfo] = []

    init(_ entries: [PhishInfo]) {
        self.entries.append(contentsOf: entries)
    }

    init(configuration: ReadConfiguration) throws {

    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard !entries.isEmpty else {
            throw FileError.nothingToExport
        }
        let encoder = CSVEncoder { $0.headers = RawPhishInfo.getHeaders() }
        let converted = entries.map({ RawPhishInfo($0) })
        let encodedData = try encoder.encode(converted)

        return FileWrapper(regularFileWithContents: encodedData)
    }
}
