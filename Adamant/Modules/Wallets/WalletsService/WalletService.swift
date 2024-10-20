//
//  WalletService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CoreData

final class WalletService: WalletServiceProtocol {
    let core: WalletCoreProtocol
    
    init(core: WalletCoreProtocol) {
        self.core = core
    }
}
