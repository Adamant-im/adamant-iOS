//
//  AddressConverterMock.swift
//  Adamant
//
//  Created by Christian Benua on 09.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import BitcoinKit
import Foundation

final class AddressConverterMock: AddressConverter {
    
    var invokedConvertAddress: Bool = false
    var invokedConvertAddressCount: Int = 0
    var stubbedInvokedConvertAddressResult: Result<Address, Error>!
    
    func convert(address: String) throws -> Address {
        invokedConvertAddress = true
        invokedConvertAddressCount += 1
        
        switch stubbedInvokedConvertAddressResult! {
        case let .failure(error):
            throw error
        case let .success(result):
            return result
        }
    }
    
    func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address {
        fatalError("\(#file).\(#function) is not implemented")
    }
    func convert(publicKey: PublicKey, type: ScriptType) throws -> Address {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
