//
//  Encodable+Dictionary.swift
//  Adamant
//
//  Created by Andrey Golubenko on 28.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

extension Encodable {
    var asDictionary: [String: Any]? {
        guard
            let data = try? JSONEncoder().encode(self),
            let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        else { return nil }
        
        return object as? [String: Any]
    }
}
