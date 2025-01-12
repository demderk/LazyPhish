//
//  EducationFile.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.10.2024.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CodableCSV

struct EducationFile: FileDocument {
    static var readableContentTypes: [UTType] = [.commaSeparatedText]

    private var educationData: [PhishingEntry] = []

    init(_ data: [PhishingEntry]) {
        self.educationData = data
    }

    init(configuration: ReadConfiguration) throws {
//        var result = [
//            "id",
//            "host",
//            "sqi",
//            "urlLength",
//            "hostLength",
//            "subDomains",
//            "prefixCount",
//            "isIP",
//            "date",
//            "opr",
//            "isPhishing",
//        ]
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = CSVEncoder { $0.headers = PhishingEntry.csvHeader }
        let encodedData = try encoder.encode(educationData)
        return FileWrapper(regularFileWithContents: encodedData)
    }

}
