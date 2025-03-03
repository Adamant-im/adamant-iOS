//
//  InfoServiceProtocol.swift
//  Adamant
//
//  Created by Anton Boyarkin on 23/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension Notification.Name {
    struct AdamantCurrencyInfoService {
        static let currencyRatesUpdated = Notification.Name("adamant.currencyInfo.rateUpdated")
    }
}

extension StoreKey {
    struct CoinInfo {
        static let selectedCurrency = "coinInfo.selectedCurrency"
    }
}

// MARK: - Currencies
enum Currency: String, CaseIterable {
    case RUB
    case USD
    case EUR
    case CNY
    case JPY
    
    var symbol: String {
        switch self {
        case .RUB: return "₽"
        case .USD: return "$"
        case .EUR: return "€"
        case .CNY: return "¥"
        case .JPY: return "¥"
        }
    }
    
    static let `default` = Currency.USD
}

// MARK: - protocol
@MainActor
protocol InfoServiceProtocol: AnyObject, Sendable {
    var currentCurrency: Currency { get set }
    
    // Check rates for list of coins
    func update()
    
    // Get rate for pair Crypto / Fiat currencies
    func getRate(for coin: String) -> Decimal?
    
    func getHistory(
        for coin: String,
        date: Date
    ) async -> InfoServiceApiResult<[InfoServiceTicker: Decimal]>
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
