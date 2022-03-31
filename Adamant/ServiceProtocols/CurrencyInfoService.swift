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


// MARK: - Currencies
enum Currency: String {
    case RUB = "RUB"
    case USD = "USD"
    case EUR = "EUR"
    case CNY = "CNY"
    case JPY = "JPY"
    
    var symbol: String {
        switch self {
        case .RUB: return "₽"
        case .USD: return "$"
        case .EUR: return "€"
        case .CNY: return "¥"
        case .JPY: return "¥"
        }
    }
    
    static var `default` = Currency.USD
}


// MARK: - protocol
protocol CurrencyInfoService: AnyObject {
    var currentCurrency: Currency { get set }
    
    // Check rates for list of coins
    func update()
    
    // Get rate for pair Crypto / Fiat currencies
    func getRate(for coin: String) -> Decimal?
    
    func getHistory(for coin: String, timestamp: Date, completion: @escaping (ApiServiceResult<[String:Decimal]?>) -> Void)
}


// MARK: - AdamantBalanceFormat fiat formatter
extension AdamantBalanceFormat {
    /// General fiat currency formatter, without currency specified
    static func fiatFormatter(for currency: Currency) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.currencyCode = currency.rawValue
        return formatter
    }
}
