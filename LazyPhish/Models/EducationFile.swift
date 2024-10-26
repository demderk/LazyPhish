//
//  EducationFile.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 18.10.2024.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

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
        var result = PhishingEntry.csvHeader + "\n"
        for item in educationData {
            result.append(item.csv + "\n")
        }
        return FileWrapper(regularFileWithContents: result.data(using: .utf8)!)
    }

}
