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
    @NSManaged public var confirmations: Int64
    @NSManaged public var fee: NSDecimalNumber?
    @NSManaged public var blockId: String?
    @NSManaged public var height: Int64
    @NSManaged public var isConfirmed: Bool
    @NSManaged public var blockchainType: String
    @NSManaged public var transactionStatusRaw: Int16
}

extension CoinTransaction : Identifiable {

}
