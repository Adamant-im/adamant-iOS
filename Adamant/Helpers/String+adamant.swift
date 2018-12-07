//
//  String+adamant.swift
//  Adamant
//
//  Created by Anton Boyarkin on 22/10/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct AdamantAddress {
    let address: String
    let name: String?
}

extension String {
    func getAdamantAddress() -> AdamantAddress? {
        let address: String?
        var name: String? = nil
        
        if let uri = AdamantUriTools.decode(uri: self) {
            switch uri {
            case .address(address: let addr, params: let params):
                address = addr
                
                if let params = params {
                    for param in params {
                        switch param {
                        case .label(let label):
                            name = label
                            break
                        }
                    }
                }
                
            case .passphrase(_):
                address = nil
            }
        } else {
            switch AdamantUtilities.validateAdamantAddress(address: self) {
            case .valid, .system:
                address = self
                
            case .invalid:
                address = nil
            }
        }
        
        if let address = address {
            return AdamantAddress(address: address, name: name)
        } else {
            return nil
        }
    }
}
