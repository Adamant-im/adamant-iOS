//
//  Collection+Extension.swift
//  
//
//  Created by Andrey Golubenko on 09.08.2023.
//

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index)
            ? self[index]
            : nil
    }
}
