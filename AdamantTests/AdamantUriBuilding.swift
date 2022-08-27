//
//  AdamantUriBuilding.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 23.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class AdamantUriBuilding: XCTestCase {
    // MARK: - Passphrases
    func testEncodingPassphrase() {
        let passphrase = "safe cabin draw case loud enlist toy smooth exchange chef clean whale"
        let encoded = AdamantUriTools.encode(request: AdamantUri.passphrase(passphrase: passphrase))
        
        XCTAssertEqual(passphrase, encoded)
    }
    
    func testDecodingPassphrase() {
        let encoded = "safe cabin draw case loud enlist toy smooth exchange chef clean whale"
        
        guard let decoded = AdamantUriTools.decode(uri: encoded) else {
            XCTFail("Decoding failed")
            return
        }
        
        switch decoded {
        case .passphrase(passphrase: let passphrase):
            XCTAssertEqual(passphrase, encoded)
            
        default:
            XCTFail("Something wrong here")
        }
    }
    
    
    // MARK: - Addresses
    func testEncodeAddress() {
        let address = "U123456789012345"
        let encoded = "adm:\(address)"
        let freshlyEncoded = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
        
        XCTAssertEqual(encoded, freshlyEncoded)
    }
    
    func testEncodeAddressWithParams() {
        let address = "U123456789012345"
        let label = "Kingsize pineapple pizza"
        let encoded = "adm:\(address)?label=\(label.replacingOccurrences(of: " ", with: "+"))"
        let freshlyEncoded = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: [AdamantAddressParam.label(label)]))
        
        XCTAssertEqual(encoded, freshlyEncoded)
    }
    
    func testDecodeAddress() {
        let address = "U123456789012345"
        let encoded = "adm:\(address)"
        
        guard let decoded = AdamantUriTools.decode(uri: encoded) else {
            XCTFail("Failed to decode.")
            return
        }
        
        switch decoded {
        case .address(address: let addressDecoded, params: let params):
            XCTAssertEqual(address, addressDecoded)
            XCTAssertNil(params)
            
        default:
            XCTFail("Something bad here")
        }
    }
    
    func testDecodeAddressWithParams() {
        let address = "U123456789012345"
        let value = "Kingsize pineapple pizza"
        let encoded = "adm:\(address)?label=\(value.replacingOccurrences(of: " ", with: "+"))"
        
        guard let decoded = AdamantUriTools.decode(uri: encoded) else {
            XCTFail("failed to decode.")
            return
        }
        
        switch decoded {
        case .address(address: let addressDecoded, params: let params):
            XCTAssertEqual(address, addressDecoded)
            guard let params = params, params.count == 1, let label = params.first else {
                XCTFail("Failed to decode params")
                return
            }
            
            switch label {
            case .label(let valueDecoded):
                XCTAssertEqual(value, valueDecoded)
            case .address, .message:
                XCTFail("Incorrect case")
            }
            
        default:
            XCTFail("Something bad there")
        }
    }
}
