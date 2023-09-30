//
//  CoinTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 26.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

extension CoinTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoinTransaction> {
        return NSFetchRequest<CoinTransaction>(entityName: "CoinTransaction")
    }

    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var transactionId: String
    @NSManaged public var coinId: String?
    @NSManaged public var senderId: String?
    @NSManaged public var recipientId: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var isOutgoing: Bool

//    public var transactionStatus: TransactionStatus?
}

extension CoinTransaction : Identifiable {

}
