//
//  CollectionUtilites.swift
//  Adamant
//
//  Created by Andrey on 01.09.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

extension Collection where Element: AnyObject {
    func hasTheSameReferences(as collection: Self) -> Bool {
        count == collection.count
            && !zip(self, collection)
                .map({ $0 === $1 })
                .contains(false)
    }
}
