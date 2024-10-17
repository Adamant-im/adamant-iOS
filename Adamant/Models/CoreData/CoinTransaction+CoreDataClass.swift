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
public class CoinTransaction: NSManagedObject, @unchecked Sendable {
    static let entityCoinName = "CoinTransaction"
    
    var transactionStatus: TransactionStatus? {
        get {
            let data = Data(transactionStatusRaw.utf8)
            return try? JSONDecoder().decode(TransactionStatus.self, from: data)
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let raw = String(data: data, encoding: .utf8)
            else {
                transactionStatusRaw = ""
                return
            }
            
            transactionStatusRaw = raw
        }
    }
}
