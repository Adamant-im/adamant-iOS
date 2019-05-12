//
//  CurrencyInfoService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 23/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension Notification.Name {
    struct AdamantCurrencyInfoService {
        static let currencyRatesUpdated = Notification.Name("adamant.currencyInfo.rateUpdated")
    }
}

protocol CurrencyInfoService: class {
    var currentCurrency: Currency { get set }
    
    // Check rates for list of coins
    func loadUpdate(for coins: [String])
    
    // Get rate for pair Crypto / Fiat currencies
    func getRate(for coin: String) -> Decimal?
    
    func getHistory(for coin: String, timestamp: Date, completion: @escaping (ApiServiceResult<[String:Decimal]?>) -> Void)
}
