//
//  CurrencyFormatterTests.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class CurrencyFormatterTests: XCTestCase {
    var decimalSeparator: String = Locale.current.decimalSeparator!
    
    func testInt() {
        let number = Decimal(123)
        let symbol = AdmWalletService.currencySymbol
        
        let format = "123 \(symbol)"
        let formatted = AdamantBalanceFormat.full.format(number, withCurrencySymbol: symbol)

        XCTAssertEqual(format, formatted)
    }

    func testFracted() {
        let number = Decimal(123.5)
        let symbol = AdmWalletService.currencySymbol
        
        let format = "123\(decimalSeparator)5 \(symbol)"
        let formatted = AdamantBalanceFormat.full.format(number, withCurrencySymbol: symbol)

        XCTAssertEqual(format, formatted)
    }

    func testZeroFracted() {
        let number = Decimal(0.53)
        let symbol = AdmWalletService.currencySymbol
        
        let format = "0\(decimalSeparator)53 \(symbol)"
        let formatted = AdamantBalanceFormat.full.format(number, withCurrencySymbol: symbol)

        XCTAssertEqual(format, formatted)
    }

    func testVerySmallFracted() {
        let number = Decimal(0.00000007)
        let symbol = AdmWalletService.currencySymbol
        
        let format = "0\(decimalSeparator)00000007 \(symbol)"
        let formatted = AdamantBalanceFormat.full.format(number, withCurrencySymbol: symbol)

        XCTAssertEqual(format, formatted)
    }
    
    func testTooSmallFracted() {
        let number = Decimal(0.0000000699)
        let symbol = AdmWalletService.currencySymbol
        
        let format = "0\(decimalSeparator)00000006 \(symbol)"
        let formatted = AdamantBalanceFormat.full.format(number, withCurrencySymbol: symbol)
        
        XCTAssertEqual(format, formatted)
    }

    func testLargeInt() {
        let number = Decimal(34903483984)
        let symbol = AdmWalletService.currencySymbol
        
        let format = "34903483984 \(symbol)"
        let formatted = AdamantBalanceFormat.full.format(number, withCurrencySymbol: symbol)
        
        XCTAssertEqual(format, formatted)
    }

    func testLargeNumber() {
        let number = Decimal(9342034.5848984)
        let symbol = AdmWalletService.currencySymbol
        
        let format = "9342034\(decimalSeparator)5848984 \(symbol)"
        let formatted = AdamantBalanceFormat.full.format(number, withCurrencySymbol: symbol)

        XCTAssertEqual(format, formatted)
    }

    func testNegative() {
        let number = Decimal(-34.504)
        let symbol = AdmWalletService.currencySymbol
        
        let format = "-34\(decimalSeparator)504 \(symbol)"
        let formatted = AdamantBalanceFormat.full.format(number, withCurrencySymbol: symbol)

        XCTAssertEqual(format, formatted)
    }
}
