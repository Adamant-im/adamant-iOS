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
    case recipient(String)
    case klyrMessage(String)
    
    init?(raw: String) {
        let keyValue = raw.split(separator: "=")
        
        guard keyValue.count == 2 else { return nil }
        
        let key = keyValue[0]
        let value = String(keyValue[1])
        
        switch key {
        case "amount":
            self = .amount(value)
        case "recipient":
            self = .recipient(value)
        case "reference":
            self = .klyrMessage(value)
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
        
        let params = url.queryItems?.compactMap {
            QQAddressParam(raw: String($0.description))
        }
        
        var recipient: String?
        
        params?.forEach({ param in
            guard case .recipient(let address) = param else {
                return
            }
            recipient = address
        })
        
        let addressRaw = recipient ?? url.path
       
        return QQAddressInformation(address: addressRaw, params: params)
    }
}
