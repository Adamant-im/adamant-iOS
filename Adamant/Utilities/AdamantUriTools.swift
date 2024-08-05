//
//  AdamantUriTools.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

enum AdamantUri {
    case passphrase(passphrase: String)
    case address(address: String, params: [AdamantAddressParam]?)
    case addressLegacy(address: String, params: [AdamantAddressParam]?)
}

enum AdamantAddressParam {
    case address(String)
    case label(String)
    case message(String)
    case amount(Double)
    
    init?(raw: String) {
        let keyValue = raw.split(separator: "=")
        if keyValue.count != 2 {
            return nil
        }
        
        switch keyValue[0] {
        case "address":
            self = .address(String(keyValue[1]))
        case "label":
            self = AdamantAddressParam.label(keyValue[1].replacingOccurrences(of: "+", with: " ").replacingOccurrences(of: "%20", with: " "))
        case "message":
            self = AdamantAddressParam.message(keyValue[1].replacingOccurrences(of: "+", with: " ").replacingOccurrences(of: "%20", with: " "))
        case "amount":
            guard let amount = Double(keyValue[1]) else { return nil }
            self = AdamantAddressParam.amount(amount)
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
        case .message(let value):
            return "message=\(value.replacingOccurrences(of: " ", with: "+"))"
        case .amount(let value):
            return "amount=\(String(value).replacingOccurrences(of: " ", with: "+"))"
        }
    }
}

final class AdamantUriTools {
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

            params?.forEach {
                switch $0 {
                case .address(let value):
                    components.queryItems?.append(.init(name: "address", value: value))
                case .label(let value):
                    components.queryItems?.append(.init(name: "label", value: value))
                case .message(let value):
                    components.queryItems?.append(.init(name: "message", value: value))
                case .amount(let value):
                    components.queryItems?.append(.init(name: "amount", value: String(value)))
                }
            }
            
            guard let uri = components.url?.absoluteString else { return "" }

            return uri
        case .addressLegacy(address: let address, params: let params):
            var components = URLComponents()
            components.scheme = AdmWalletService.qqPrefix
            components.host = address
            components.queryItems = (params?.count ?? .zero) > .zero ? [] : nil
            
            params?.forEach {
                switch $0 {
                case .address:
                    break
                case .label(let value):
                    components.queryItems?.append(.init(name: "label", value: value))
                case .message(let value):
                    components.queryItems?.append(.init(name: "message", value: value))
                case .amount(let value):
                    components.queryItems?.append(.init(name: "amount", value: String(value)))
                }
            }
            
            guard let uri = components.url?.absoluteString.replacingOccurrences(of: "://", with: ":")
            else { return "" }

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
        guard request.count == 2,
              request[0].caseInsensitiveCompare(AdmWalletService.qqPrefix) == .orderedSame
        else { return nil }
        
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
