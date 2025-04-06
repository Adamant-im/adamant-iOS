//
//  TransferTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import CoreData
import Foundation

@objc(TransferTransaction)
public class TransferTransaction: ChatTransaction, @unchecked Sendable {
    static let entityName = "TransferTransaction"
}
