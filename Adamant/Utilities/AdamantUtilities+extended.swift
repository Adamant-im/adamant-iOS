//
//  AdamantUtilities.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantUtilities {
    // MARK: Application version
    static var applicationVersion: String = {
        if let infoDictionary = Bundle.main.infoDictionary,
            let version = infoDictionary["CFBundleShortVersionString"] as? String,
            let build = infoDictionary["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        
        return ""
    }()
    
    // MARK: Device model
    static var deviceModelCode: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
                
            }
        }
        return modelCode ?? "Unknown"
    }
}


// MARK: - Validating Addresses and Passphrases
extension AdamantUtilities {
    static let addressRegexString = "^U([0-9]{6,20})$"
    static let passphraseRegexString = "^([a-z]* ){11}([a-z]*)$"
    static let passphraseRegex = try! NSRegularExpression(pattern: passphraseRegexString, options: [])
    static let addressRegex = try! NSRegularExpression(pattern: addressRegexString, options: [])
    
    enum AddressValidationResult {
        case valid
        case system
        case invalid
    }
    
    /// Rules are simple:
    ///
    /// - Leading uppercase U
    /// - From 6 to 20 numbers
    /// - No leading or trailing whitespaces
    /// - System addresses are allowed. Enum is AdamantContacts.systemAddresses
    static func validateAdamantAddress(address: String) -> AddressValidationResult {
        if validate(string: address, with: addressRegex) {
            return .valid
        } else if AdamantContacts.systemAddresses.contains(address) {
            return .system
        } else {
            return .invalid
        }
    }
    
    /// Rules are simple:
    ///
    /// - No leading and/or trailing whitespaces
    /// - No UPPERCASE letters
    /// - No numbers
    /// - No -$%èçïäł- caracters
    /// - 12 words, splitted by a single whitespace
    /// - a-z
    static func validateAdamantPassphrase(passphrase: String) -> Bool {
        guard validate(string: passphrase, with: passphraseRegex) else {
            return false
        }
        
        for word in passphrase.split(separator: " ") {
            if !WordList.english.contains(word) {
                return false
            }
        }
        
        return true
    }
    
    private static func validate(string: String, with regex: NSRegularExpression) -> Bool {
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        
        return matches.count == 1
    }
}


// MARK: - Hex
extension AdamantUtilities {
    static func getHexString(from bytes: [UInt8]) -> String {
        if bytes.count > 0 {
            return Data(bytes: bytes).reduce("") {$0 + String(format: "%02x", $1)}
        } else {
            return ""
        }
    }
    
    static func getBytes(from hex: String) -> [UInt8] {
        let hexa = Array(hex)
        return stride(from: 0, to: hex.count, by: 2).compactMap { UInt8(String(hexa[$0..<$0.advanced(by: 2)]), radix: 16) }
    }
}

// MARK: - JSON
extension AdamantUtilities {
    static func json(from object:Any) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [])
            return String(data: data, encoding: String.Encoding.utf8)
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    static func toArray(text: String) -> [String]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
