//
//  CoinStorage.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 26.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol CoinStorageService: AnyObject {
    func append(_ transaction: TransactionDetails)
    func append(_ transactions: [TransactionDetails])
}
