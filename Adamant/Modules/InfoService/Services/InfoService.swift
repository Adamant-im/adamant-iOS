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

final class InfoService: InfoServiceProtocol {
    private let securedStore: SecuredStore
    private let api: InfoServiceApiServiceProtocol
    private let rateCoins: [String]
    private let queue = ConcurrencyQueue()
    
    @Atomic private var rates = [InfoServiceTicker: Decimal]()
    @Atomic private var currentCurrencyValue: Currency = .default
    @Atomic private var subscriptions = Set<AnyCancellable>()
    
    var currentCurrency: Currency {
        get { currentCurrencyValue }
        set { updateCurrency(newValue) }
    }
    
    init(
        securedStore: SecuredStore,
        walletServiceCompose: WalletServiceCompose,
        api: InfoServiceApiServiceProtocol
    ) {
        self.securedStore = securedStore
        self.api = api
        rateCoins = walletServiceCompose.getWallets().map { $0.core.tokenSymbol }
        setupCurrency()
        setupObservers()
    }
    
    func update() {
        queue.syncAdd { [weak self, rateCoins] in
            (try? await self?.api.loadRates(coins: rateCoins).get()).map {
                self?.rates = $0
                self?.sendRatesChangedNotification()
            }
        }
    }
    
    func getRate(for coin: String) -> Decimal? {
        rates[.init(crypto: coin, fiat: currentCurrency.rawValue)]
    }
    
    func getHistory(
        for coin: String,
        date: Date
    ) async -> InfoServiceApiResult<[InfoServiceTicker: Decimal]> {
        await api.getHistory(coin: coin, date: date).map { $0.tickers }
    }
}

private extension InfoService {
    func sendRatesChangedNotification() {
        NotificationCenter.default.post(
            name: .AdamantCurrencyInfoService.currencyRatesUpdated,
            object: nil
        )
    }
    
    func updateCurrency(_ newValue: Currency) {
        $currentCurrencyValue.mutate { value in
            guard newValue != value else { return }
            value = newValue
            securedStore.set(value.rawValue, for: StoreKey.CoinInfo.selectedCurrency)
            sendRatesChangedNotification()
        }
    }
    
    func setupObservers() {
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.update() }
            .store(in: &subscriptions)
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
