//
//  RichMessageTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData
import CommonKit

@objc(RichMessageTransaction)
public class RichMessageTransaction: ChatTransaction {
    static let entityName = "RichMessageTransaction"
    
    override func serializedMessage() -> String? {
        return richContentSerialized
    }
    
    override var transactionStatus: TransactionStatus? {
        get {
            TransactionStatus(rawValue: transactionStatusRaw)
        }
        set {
            let raw = newValue?.rawValue ?? .zero
            guard raw != transactionStatusRaw else { return }
            transactionStatusRaw = newValue?.rawValue ?? .zero
        }
    }
    
    var transfer: RichMessageTransfer? {
        guard let richContent = richContent else { return nil }
        return .init(content: richContent)
    }
}
