//
//  AccountServiceMock.swift
//  Adamant
//
//  Created by Christian Benua on 28.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CommonKit

final class AccountServiceMock: AccountService {
    var state: AccountServiceState = .loggedIn
    
    var isBalanceExpired: Bool = false
    var hasStayInAccount: Bool = false
    var useBiometry: Bool = false
    
    var account: AdamantAccount?
    var keypair: Keypair?
    
    func update() {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func update(_ completion: (@Sendable (AccountServiceResult) -> Void)?) {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func loginWith(passphrase: String) async throws -> AccountServiceResult {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func loginWithStoredAccount() async throws -> AccountServiceResult {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func logout() {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func reloadWallets() {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func setStayLoggedIn(pin: String, completion: @escaping @Sendable (AccountServiceResult) -> Void) {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func dropSavedAccount() {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func validatePin(_ pin: String) -> Bool {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func updateUseBiometry(_ newValue: Bool) {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
