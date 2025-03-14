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
    var isSecretWalletsEnabled: Bool
    var secretWalletPassword: String
    
    static let `default` = Self(
        passphrase: .empty,
        keys: .init(),
        buttonDescription: .init(),
        isLoading: false,
        isSecretWalletsEnabled: false,
        secretWalletPassword: ""
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
