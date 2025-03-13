//
//  CoreData+Helpers.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 21.02.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CoreData

extension Array where Element == NSSortDescriptor {
    static func sortChatTransactions(ascending: Bool) -> [NSSortDescriptor] {
        [
            NSSortDescriptor(key: "timestampMs", ascending: ascending),
            NSSortDescriptor(key: "transactionId", ascending: ascending)
        ]
    }
}
