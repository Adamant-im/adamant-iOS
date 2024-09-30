//
//  InfoService.swift
//  Adamant
//
//  Created by Andrew G on 24.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Combine
import CommonKit
import UIKit

@MainActor
final class InfoService: InfoServiceProtocol {
    typealias Rates = [InfoServiceTicker: Decimal]
    
    private let securedStore: SecuredStore
    private let api: InfoServiceApiServiceProtocol
    private let rateCoins: [String]
    
    private var rates = Rates()
    private var currentCurrencyValue: Currency = .default
    private var subscriptions = Set<AnyCancellable>()
    private var isUpdating = false
    
    var currentCurrency: Currency {
        get { currentCurrencyValue }
        set { updateCurrency(newValue) }
    }
    
    nonisolated init(
        securedStore: SecuredStore,
        walletServiceCompose: WalletServiceCompose,
        api: InfoServiceApiServiceProtocol
    ) {
        self.securedStore = securedStore
        self.api = api
        rateCoins = walletServiceCompose.getWallets().map { $0.core.tokenSymbol }
        Task { @MainActor in configure() }
    }
    
    func update() {
        Task {
            guard !isUpdating else { return }
            isUpdating = true
            defer { isUpdating = false }
            
            guard let newRates = try? await api.loadRates(coins: rateCoins).get() else { return }
            rates = newRates
            sendRatesChangedNotification()
        }
    }
    
    func getRate(for coin: String) -> Decimal? {
        rates[.init(crypto: coin, fiat: currentCurrency.rawValue)]
    }
    
    func getHistory(
        for coin: String,
        date: Date
    ) async -> InfoServiceApiResult<[InfoServiceTicker: Decimal]> {
        await api.getHistory(coin: coin, date: date).flatMap {
            abs(date.timeIntervalSince($0.date)) < historyThreshold
                ? .success($0.tickers)
                : .failure(.inconsistentData)
        }
    }
}

private extension InfoService {
    func configure() {
        setupCurrency()
        
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in Task { [weak self] in self?.update() } }
            .store(in: &subscriptions)
    }
    
    func sendRatesChangedNotification() {
        NotificationCenter.default.post(
            name: .AdamantCurrencyInfoService.currencyRatesUpdated,
            object: nil
        )
    }
    
    func updateCurrency(_ newValue: Currency) {
        guard newValue != currentCurrencyValue else { return }
        currentCurrencyValue = newValue
        securedStore.set(currentCurrencyValue.rawValue, for: StoreKey.CoinInfo.selectedCurrency)
        sendRatesChangedNotification()
    }
    
    func setupCurrency() {
        if
            let id: String = securedStore.get(StoreKey.CoinInfo.selectedCurrency),
            let currency = Currency(rawValue: id)
        {
            currentCurrency = currency
        } else {
            currentCurrency = .default
        }
    }
}

private let historyThreshold: TimeInterval = 86400
