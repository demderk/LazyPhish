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
        print(String(decoding: encodedData, as: UTF8.self))
        return FileWrapper(regularFileWithContents: encodedData)
    }
}
