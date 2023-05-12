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
    let params: [QQAddressParams]?
}

enum QQAddressParams {
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

class AdamantCoinTools {
    static func decode(uri: String, qqPrefix: String) -> QQAddressInformation? {
        if uri.isEmpty {
            return nil
        }
        
        let request = uri.split(separator: ":")
        if request.count > 2 || request[0] != qqPrefix {
            return nil
        }
        
        let addressAndParams = request[1].split(separator: "?")
        guard let addressRaw = addressAndParams.first else {
            return nil
        }
        
        var params: [QQAddressParams]? = nil
        if addressAndParams.count > 1 {
            let p = addressAndParams[1].split(separator: "&").compactMap {
                QQAddressParams(raw: String($0))
            }
            
            params = p.count > 0 ? p : nil
        }
        
        let address = QQAddressInformation(address: String(addressRaw), params: params)
        return address
    }
}
