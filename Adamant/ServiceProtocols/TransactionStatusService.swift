//
//  TransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData

protocol TransactionStatusService: Actor, AnyObject {
    func forceUpdate(transaction: CoinTransaction) async
    func startObserving()
}
