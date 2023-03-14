//
//  RichTransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData

protocol RichTransactionStatusService: Actor, AnyObject {
    func forceUpdate(transaction: RichMessageTransaction) async
}
