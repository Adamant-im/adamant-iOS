//
//  PKGeneratorState.swift
//  Adamant
//
//  Created by Andrew G on 28.11.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit

struct PKGeneratorState {
    var passphrase: String
    var keys: [KeyInfo]
    var buttonDescription: AttributedString
    var isLoading: Bool
    
    static let `default` = Self(
        passphrase: .empty,
        keys: .init(),
        buttonDescription: .init(),
        isLoading: false
    )
}

extension PKGeneratorState {
    struct KeyInfo: Identifiable {
        var id: String { title }
        
        let title: String
        let description: String
        let icon: UIImage
        let key: String
    }
}
