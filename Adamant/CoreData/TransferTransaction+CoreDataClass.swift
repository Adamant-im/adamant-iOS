//
//  TransferTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(TransferTransaction)
public class TransferTransaction: BaseTransaction {
	static let entityName = "TransferTransaction"
	
	var isOutgoing: Bool = false
}
