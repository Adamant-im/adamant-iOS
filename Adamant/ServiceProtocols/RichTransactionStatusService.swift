//
//  RichTransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData

protocol RichTransactionStatusService: AnyObject {
    func update(
        _ transaction: RichMessageTransaction,
        parentContext: NSManagedObjectContext,
        resetBeforeUpdate: Bool
    ) async throws
}
