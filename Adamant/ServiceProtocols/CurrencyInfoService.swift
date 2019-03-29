//
//  CurrencyInfoService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 23/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

protocol CurrencyInfoService: class {
    var currentCurrency: Currency { get set }
    
    // Check rates for list of coins
    func loadUpdate(for coins: [String])
    
    // Get rate for pair Crypto / Fiat currencies
    func getRate(for coin: String) -> Double
}
