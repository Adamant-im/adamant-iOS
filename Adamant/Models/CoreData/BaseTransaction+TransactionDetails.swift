//
//  BaseTransaction+TransactionDetails.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension BaseTransaction {
    var block: UInt {
        if let raw = blockId, let id = UInt(raw) {
            return id
        } else {
            return 0
        }
    }
}
