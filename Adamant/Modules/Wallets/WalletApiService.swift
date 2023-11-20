//
//  WalletApiService.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol WalletApiService {
    var preferredNodeIds: [UUID] { get }
    
    func healthCheck()
}
