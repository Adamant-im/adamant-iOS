//
//  TransactionsStatusServiceProtocol.swift
//  Adamant
//
//  Created by Andrew G on 18.10.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

@TransactionsStatusActor
protocol TransactionsStatusServiceComposeProtocol {
    func forceUpdate(transaction: CoinTransaction) async
    func startObserving()
}
