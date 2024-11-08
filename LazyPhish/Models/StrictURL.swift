//
//  StrictURL.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

import Foundation
import OSLog

struct StrictURL {
    
    // There are
    // static let twoSLDs: [String]
    
    var URL: URL
    
    var strictHost: String {
        URL.host()!
    }
    
    var strictURL: String { URL.absoluteString }
    
    var hostRoot: String {
        return StrictURL.getTLD(host: strictHost) ?? strictHost
    }
    
    var isTwoSLD: Bool {
        return StrictURL.isTwoSLD(host: strictHost)
    }
    
    /// Returns host without protocol and www
    var cleanHost: String { clearString(str: strictHost) }
    
    /// Returns URL string without protocol and www
    var cleanURL: String { clearString(str: strictURL) }
    
    init(url: String) throws {
        URL = try PhishInfoFormatter.validURL(url)
    }
    
    init(url: String, preActions: Set<FormatPreaction>) throws {
        URL = try PhishInfoFormatter.validURL(url, preActions: preActions)
    }
    
    private func clearString(str: String) -> String {
        var result: String = str
        if result.count > 8 {
            result = result.replacing(
                "https://",
                subrange: str.startIndex..<str.index(str.startIndex, offsetBy: 8),
                with: { _ in return "" })
        }
        if result.count > 7 {
            result = result.replacing(
                "http://",
                subrange: str.startIndex..<str.index(str.startIndex, offsetBy: 7),
                with: { _ in return "" })
        }
        if result.count > 4 {
            result = result.replacing(
                "www.",
                subrange: str.startIndex..<str.index(str.startIndex, offsetBy: 4)
                , with: { _ in return "" })
        }
        
        return result
    }
}
