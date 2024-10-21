//
//  ApiServiceComposeProtocol.swift
//  Adamant
//
//  Created by Andrew G on 21.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

protocol ApiServiceComposeProtocol {
    func chosenFastestNodeId(group: NodeGroup) async -> UUID?
    func hasActiveNode(group: NodeGroup) async -> Bool
    func healthCheck(group: NodeGroup)
}
