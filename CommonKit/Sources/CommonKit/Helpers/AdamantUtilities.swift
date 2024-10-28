//
//  AdamantUtilities.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import os

public enum AdamantUtilities {
    public enum Git {}
    
    public static let admCurrencyExponent: Int = -8
    
    // MARK: - Dates
    
    public static func encodeAdamant(date: Date) -> TimeInterval {
        return date.timeIntervalSince1970 - magicAdamantTimeInterval
    }
    
    public static func decodeAdamant(timestamp: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: timestamp + magicAdamantTimeInterval)
    }
    
    private static let magicAdamantTimeInterval: TimeInterval = {
        // JS handles moth as 0-based number, swift handles month as 1-based number.
        let components = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(abbreviation: "UTC"), year: 2017, month: 9, day: 2, hour: 17)
        return components.date!.timeIntervalSince1970
    }()
    
    // MARK: - JSON
    
    public static func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : []
        
        if JSONSerialization.isValidJSONObject(value) {
            if let data = try? JSONSerialization.data(withJSONObject: value, options: options) {
                if let string = String(data: data, encoding: .utf8) {
                    return string
                }
            }
        }
        
        return ""
    }
    
    /// Address generation algorithm:
    ///  https://github.com/Adamant-im/adamant/wiki/Generating-ADAMANT-account-and-key-pair#3-a-users-adm-wallet-address-is-generated-from-the-publickeys-sha-256-hash
    public static func generateAddress(publicKey: String) -> String {
        let publicKeyHashBytes = publicKey.hexBytes().sha256()
        let data = Data(publicKeyHashBytes)
        let number = data.withUnsafeBytes { $0.load(as: UInt64.self) }
        return "U\(number)"
    }
    
    public static func consoleLog(_ args: String..., separator: String = " ") {
        let message = args.joined(separator: separator)
        os_log("adamant-console-log %{public}@", message)
    }
}

public extension AdamantUtilities.Git {
    static let commitHash = Bundle.module.url(
        forResource: "GitData",
        withExtension: "plist"
    ).flatMap { NSDictionary(contentsOf: $0)?.value(forKey: "CommitHash") as? String }
}
