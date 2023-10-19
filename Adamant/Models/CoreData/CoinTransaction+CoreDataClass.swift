//
//  CoinTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 26.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoinTransaction)
public class CoinTransaction: NSManagedObject {
    static let entityCoinName = "CoinTransaction"
    
    var transactionStatus: TransactionStatus? {
        get {
            TransactionStatus(rawValue: transactionStatusRaw)
        }
        set {
            let raw = newValue?.rawValue ?? .zero
            guard raw != transactionStatusRaw else { return }
            transactionStatusRaw = newValue?.rawValue ?? .zero
        }
    }
}
