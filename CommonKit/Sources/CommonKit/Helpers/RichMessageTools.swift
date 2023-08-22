//
//  RichMessageTools.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public enum RichMessageTools {
    public static func richContent(from data: Data) -> [String: Any]? {
        guard let jsonRaw = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        
        switch jsonRaw {
            // Valid format
        case var json as [String:String]:
            if let key = json[RichContentKeys.type] {
                json[RichContentKeys.type] = key.lowercased()
            }
            
            return json
            
            // Broken format, try to fix it
        case var json as [String:Any]:
            if let key = json[RichContentKeys.type] as? String {
                json[RichContentKeys.type] = key.lowercased()
            }
            
            var fixedJson: [String: Any] = [:]
            
            let formatter = AdamantBalanceFormat.rawNumberDotFormatter
            formatter.decimalSeparator = "."
            
            for (key, raw) in json {
                if let value = raw as? String {
                    fixedJson[key] = value
                } else if let value = raw as? NSNumber, let amount = formatter.string(from: value) {
                    fixedJson[key] = amount
                } else if let value = raw as? [String: String] {
                    fixedJson[key] = value
                } else {
                    fixedJson[key] = raw
                }
            }
            
            return fixedJson
            
        default:
            return nil
        }
    }
}
