//
//  WalletsStoreService.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 08.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

protocol WalletStoreServiceProtocol: AnyObject {
    func sorted(includeInvisible: Bool) -> [WalletService]
    func isInvisible(_ wallet: WalletService) -> Bool
}
