//
//  VisibleWalletsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import CommonKit
import Foundation

protocol VisibleWalletsService: AnyObject, Sendable {
    var statePublisher: AnyObservable<Void> { get }
    
    func addToInvisibleWallets(_ walletID: String)
    func removeFromInvisibleWallets(_ walletID: String)
    func getSortedWallets(includeInvisible: Bool) -> [String]
    func isInvisible(_ walletID: String) -> Bool
    
    func setIndexPositionWallets(_ indexes: [String], includeInvisible: Bool)
    
    func reset()
}
