//
//  CoinStorage.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 26.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Combine
import CommonKit

protocol CoinStorageService: AnyObject {
    var transactionsPublisher: any Observable<[TransactionDetails]> {
        get
    }
    
    func append(_ transaction: TransactionDetails)
    func append(_ transactions: [TransactionDetails])
    func clear()
    func updateStatus(for transactionId: String, status: TransactionStatus?)
}
