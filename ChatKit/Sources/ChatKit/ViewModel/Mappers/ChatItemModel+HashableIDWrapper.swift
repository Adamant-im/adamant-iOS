//
//  ChatItemModel+HashableIDWrapper.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

extension Sequence where Element == ChatItemModel {
    func wrappedByHashableId() -> [HashableIDWrapper<ChatItemModel>] {
        var identifierTable: [String: Int] = [:]
        var result: [HashableIDWrapper<ChatItemModel>] = []
        
        forEach { item in
            let index = identifierTable[item.identifier] ?? .zero
            identifierTable[item.identifier] = index + 1
            
            result.append(.init(
                identifier: .init(identifier: item.identifier, index: index),
                value: item
            ))
        }
        
        return result
    }
}
