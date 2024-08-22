//
//  WalletApiServiceComposeProtocol.swift
//  Adamant
//
//  Created by Andrew G on 21.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

protocol WalletApiServiceComposeProtocol {
    func chosenFastestNodeId(group: NodeGroup) -> UUID?
    func hasActiveNode(group: NodeGroup) -> Bool
    func healthCheck(group: NodeGroup)
}
