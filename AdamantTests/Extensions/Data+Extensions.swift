//
//  Data+Extensions.swift
//  Adamant
//
//  Created by Christian Benua on 03.02.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation

private final class BundleTag {}

extension Data {
    static func readResource(name: String, withExtension extensionName: String?) -> Data? {
        Bundle(for: BundleTag.self)
            .url(forResource: name, withExtension: extensionName)
            .flatMap { try? Data(contentsOf: $0) }
    }
}
