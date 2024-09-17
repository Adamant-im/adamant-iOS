//
//  ApiServiceProtocol.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public protocol ApiServiceProtocol {
    var chosenFastestNodeId: UUID? { get }
    var hasActiveNode: Bool { get }
    
    func healthCheck()
}
