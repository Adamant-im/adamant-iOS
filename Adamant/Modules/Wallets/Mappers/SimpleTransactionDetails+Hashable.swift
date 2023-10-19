//
//  SimpleTransactionDetails+Hashable.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

extension Sequence where Element == SimpleTransactionDetails {
    func wrappedByHashableId() -> [HashableIDWrapper<SimpleTransactionDetails>] {
        var identifierTable: [String: Int] = [:]
        var result: [HashableIDWrapper<SimpleTransactionDetails>] = []
        
        forEach { item in
            let index = identifierTable[item.txId] ?? .zero
            identifierTable[item.txId] = index + 1
            
            result.append(.init(
                identifier: .init(identifier: item.txId, index: index),
                value: item
            ))
        }
        
        return result
    }
}
