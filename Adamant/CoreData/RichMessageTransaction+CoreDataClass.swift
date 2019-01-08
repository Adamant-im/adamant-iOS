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
import MessageKit

@objc(RichMessageTransaction)
public class RichMessageTransaction: ChatTransaction {
    static let entityName = "RichMessageTransaction"
    
    override func serializedMessage() -> String? {
        if let richContent = richContent, let data = try? JSONEncoder().encode(richContent), let raw = String(data: data, encoding: String.Encoding.utf8) {
            return raw
        } else {
            return nil
        }
    }
    
    override var transactionStatus: TransactionStatus? {
        get {
            if let raw = transferStatusRaw {
                return TransactionStatus(rawValue: raw.int16Value)
            } else {
                return nil
            }
        }
        set {
            if let raw = newValue {
                transferStatusRaw = raw.rawValue as NSNumber
            } else {
                transferStatusRaw = nil
            }
        }
    }
    
    public var kind: MessageKind = .text("?")
}
