//
//  TxStatusServiceProtocol.swift
//  Adamant
//
//  Created by Andrew G on 18.10.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

@TransactionsStatusActor
protocol TxStatusServiceProtocol: AnyObject {
    func add(transaction: CoinTransaction)
    func remove(transaction: CoinTransaction)
    func forceUpdate(transaction: CoinTransaction) async
}
