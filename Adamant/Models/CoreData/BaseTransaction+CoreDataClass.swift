//
//  BaseTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(BaseTransaction)
public class BaseTransaction: CoinTransaction {
    var transactionStatus: TransactionStatus? {
        return nil
    }
}
