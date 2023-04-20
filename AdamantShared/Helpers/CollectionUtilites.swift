//
//  CollectionUtilites.swift
//  Adamant
//
//  Created by Andrey on 01.09.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index)
            ? self[index]
            : nil
    }
}

extension Collection where Element: AnyObject {
    func hasTheSameReferences(as collection: Self) -> Bool {
        count == collection.count
            && !zip(self, collection)
                .map({ $0 === $1 })
                .contains(false)
    }
}
