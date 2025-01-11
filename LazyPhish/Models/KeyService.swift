//
//  KeyService.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 26.08.2024.
//

import Foundation

enum KeyServicePath: String, CaseIterable {
    case virusTotal = "VirusTotal"
    case opr = "OPRKey"
}

protocol KeyServiceBehavior: AnyObject {
    static var inited: Bool { get }
    static var VTKey: String? { get }
    static var OPRKey: String? { get }

    static func saveAllKeys(virusTotal: String, opr: String)

    static func saveKeychainKey(data: String, path: KeyServicePath)

    static func readKeychainKey(path: KeyServicePath,
                                action: @escaping (String?) -> Void)

    static func refreshAllKeys()
}

#if DEBUG

class KeyService: KeyServiceBehavior {
    public static var inited: Bool = false
    public static var VTKey: String? {
        lastSucceedVTKey
    }
    public static var OPRKey: String? {
        lastSucceedOPR
    }

    private static let serviceName = "com.LazyFusion.LazyPhish.Keys"
    private static var lastSucceedVTKey: String? {
        didSet {
            if !inited {
                inited = true
            }
        }
    }
    private static var lastSucceedOPR: String? {
        didSet {
            if !inited {
                inited = true
            }
        }
    }

    static private func buildReadQuery(path: KeyServicePath) -> CFDictionary {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: path.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        return query as CFDictionary
    }

    static private func buildWriteQuery(data: String, path: KeyServicePath) -> CFDictionary {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: path.rawValue,
            kSecValueData as String: data.data(using: .utf8)!
        ]

        return query as CFDictionary
    }

    static private func writeKeychain(data: String, path keyChain: KeyServicePath, force: Bool = false) {
        DispatchQueue.global().async {

            let query = buildWriteQuery(data: data, path: keyChain)

            if force {
                SecItemDelete(query as CFDictionary)
                SecItemAdd(query as CFDictionary, nil)
            } else {
                var found = false
                switch keyChain {
                case .virusTotal:
                    found = lastSucceedVTKey == data
                case .opr:
                    found = lastSucceedOPR == data
                }
                if !found {
                    SecItemDelete(query as CFDictionary)
                    SecItemAdd(query as CFDictionary, nil)
                    switch keyChain {
                    case .virusTotal:
                        lastSucceedVTKey = data
                    case .opr:
                        lastSucceedOPR = data
                    }
                }
            }

        }
    }

    static private func readKeychain(path keyChain: KeyServicePath,
                                     action: @escaping (String?) -> Void
    ) {
        DispatchQueue.global().async {

            let query = buildReadQuery(path: keyChain)
            var item: AnyObject?
            SecItemCopyMatching(query as CFDictionary, &item)

            if let success = item as? Data, let str = String(data: success, encoding: .utf8) {
                action(str)
            } else {
                action(nil)
            }
        }
    }

    static func saveAllKeys(virusTotal: String, opr: String) {
        writeKeychain(data: virusTotal, path: .virusTotal)
        writeKeychain(data: opr, path: .opr)
    }

    static func saveKeychainKey(data: String, path: KeyServicePath) {
        writeKeychain(data: data, path: path)
    }

    static func readKeychainKey(path: KeyServicePath,
                                action: @escaping (String?) -> Void
    ) {
        readKeychain(path: path) { data in
            guard data != nil else {
                action(nil)
                return
            }
            switch path {
            case .virusTotal:
                lastSucceedVTKey = data
            case .opr:
                lastSucceedOPR = data
            }
            action(data)
        }
    }

    static func refreshAllKeys() {
        readKeychain(path: .virusTotal) { key in lastSucceedVTKey = key }
        readKeychain(path: .opr) { key in lastSucceedOPR = key }
    }
}

#endif

#if RELEASE

// MARK: KeyService for LazyPhish Community

class KeyService: KeyServiceBehavior {
    static var inited: Bool { true }
    static var VTKey: String? {
        value(.virusTotal)
    }
    static var OPRKey: String? { value(.opr) }
        
    static private func value(_ path: KeyServicePath) -> String? {
        let data = UserDefaults.standard.string(forKey: path.rawValue)
        return data
    }
    
    static func saveAllKeys(virusTotal: String, opr: String) {
        saveKeychainKey(data: virusTotal, path: .virusTotal)
        saveKeychainKey(data: opr, path: .opr)
    }
    
    static func saveKeychainKey(data: String, path: KeyServicePath) {
        UserDefaults.standard.set(data, forKey: path.rawValue)
    }
    
    // Used for new KeyChain Code compatibility
    static func readKeychainKey(path: KeyServicePath, action: @escaping (String?) -> Void) {
        action(value(path))
    }
    
    static func refreshAllKeys() {
        readKeychainKey(path: .opr, action: { _ in })
        readKeychainKey(path: .virusTotal, action: { _ in })
    }
    
}

#endif
