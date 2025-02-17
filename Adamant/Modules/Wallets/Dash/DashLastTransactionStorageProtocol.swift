//
//  DashLastTransactionStorageProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 22.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

protocol DashLastTransactionStorageProtocol: AnyObject {
    func getLastTransactionId() -> String?
    func setLastTransactionId(_ id: String?)
}
