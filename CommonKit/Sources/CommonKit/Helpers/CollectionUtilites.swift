//
//  CollectionUtilites.swift
//  Adamant
//
//  Created by Andrey on 01.09.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Array {
    subscript(safe index: Index) -> Element? {
        get {
            indices.contains(index) ? self[index] : nil
        } set {
            guard indices.contains(index), let newValue = newValue else { return }
            self[index] = newValue
        }
    }
}

public extension Collection where Element: AnyObject {
    func hasTheSameReferences(as collection: Self) -> Bool {
        count == collection.count
            && !zip(self, collection)
                .map({ $0 === $1 })
                .contains(false)
    }
}
