//
//  AdamantCoinTools.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 12.05.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct QQAddressInformation {
    let address: String
    let params: [QQAddressParam]?
}

enum QQAddressParam {
    case amount(String)
    
    init?(raw: String) {
        let keyValue = raw.split(separator: "=")
        
        guard keyValue.count == 2 else { return nil }
        
        let key = keyValue[0]
        let value = String(keyValue[1])
        
        switch keyValue[0] {
        case "amount":
            self = .amount(value)
        default:
            return nil
        }
    }
}

final class AdamantCoinTools {
    static func decode(uri: String, qqPrefix: String) -> QQAddressInformation? {
        let url = URLComponents(string: uri)
        
        guard !uri.isEmpty,
              let url = url,
              let raw = url.string
        else {
            return nil
        }
        
        guard let prefix = uri.split(separator: ":").first,
              prefix.caseInsensitiveCompare(qqPrefix) == .orderedSame
        else {
            return QQAddressInformation(address: raw, params: nil)
        }
        
        let addressRaw = url.path
        
        let params = url.queryItems?.compactMap {
            QQAddressParam(raw: String($0.description))
        }
        
        return QQAddressInformation(address: addressRaw, params: params)
    }
}
