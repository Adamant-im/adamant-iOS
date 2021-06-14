//
//  AdamantUriTools.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum AdamantUri {
    case passphrase(passphrase: String)
    case address(address: String, params: [AdamantAddressParam]?)
}

enum AdamantAddressParam {
    case address(String)
    case label(String)
    
    init?(raw: String) {
        let keyValue = raw.split(separator: "=")
        if keyValue.count != 2 {
            return nil
        }
        
        switch keyValue[0] {
        case "address":
            self = .address(String(keyValue[1]))
        case "label":
            self = AdamantAddressParam.label(keyValue[1].replacingOccurrences(of: "+", with: " "))
        
        default:
            return nil
        }
    }
    
    var encoded: String {
        switch self {
        case .address(let value):
            return "address=\(value)"
        case .label(let value):
            return "label=\(value.replacingOccurrences(of: " ", with: "+"))"
        }
    }
}

class AdamantUriTools {
    static let AdamantProtocol = "adm"
    static let AdamantHost = "https://msg.adamant.im"
    
    static func encode(request: AdamantUri) -> String {
        switch request {
        case .passphrase(passphrase: let passphrase):
            return passphrase
            
        case .address(address: let address, params: let params):
            var components = URLComponents()
            components.scheme = "https"
            components.host = "msg.adamant.im"
            components.queryItems = [
                .init(name: "address", value: address)
            ]
            guard let uri = components.url?.absoluteString else { return "" }

            params?.forEach {
                switch $0 {
                case .address(let value):
                    components.queryItems?.append(.init(name: "address", value: value))
                case .label(let value):
                    components.queryItems?.append(.init(name: "label", value: value))
                }
            }

            return uri
        }
    }
    
    static func decode(uri: String) -> AdamantUri? {
        if uri.count == 0 {
            return nil
        }
        
        if AdamantUtilities.validateAdamantPassphrase(passphrase: uri) {
            return AdamantUri.passphrase(passphrase: uri)
        }
        
        let request = uri.split(separator: ":")
        if request.count > 2 || request[0] != AdamantProtocol {
            return nil
        }
        
        let addressAndParams = request[1].split(separator: "?")
        guard let addressRaw = addressAndParams.first else {
            return nil
        }
        
        let address = String(addressRaw)
        switch AdamantUtilities.validateAdamantAddress(address: address) {
        case .valid:
            break
            
        case .system, .invalid:
            return nil
        }
        
        let params: [AdamantAddressParam]?
        if addressAndParams.count > 1 {
            var p = [AdamantAddressParam]()
            
            for param in addressAndParams[1].split(separator: "&").compactMap({ AdamantAddressParam(raw: String($0)) }) {
                p.append(param)
            }
            
            if p.count > 0 {
                params = p
            } else {
                params = nil
            }
        } else {
            params = nil
        }
        
        return AdamantUri.address(address: address, params: params)
    }
    
    private init() {}
}
