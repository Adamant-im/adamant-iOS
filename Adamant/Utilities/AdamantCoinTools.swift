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
              let url = url
        else {
            return nil
        }
        
        let array = uri.split(separator: ":")
        
        guard array.count > 1,
              let prefix = array.first 
        else {
            return parseAdress(url: url)
        }
        
        guard prefix.caseInsensitiveCompare(qqPrefix) == .orderedSame else {
            return nil
        }
        
        return parseAdress(url: url)
    }
    
    private class func parseAdress(url: URLComponents) -> QQAddressInformation {
        let addressRaw = url.path
        
        let params = url.queryItems?.compactMap {
            QQAddressParam(raw: String($0.description))
        }
        
        return QQAddressInformation(address: addressRaw, params: params)
    }
}
