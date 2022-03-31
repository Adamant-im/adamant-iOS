//
//  AccountsResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 12/31/17.
//

import Foundation

extension Accounts {

    public struct LegacyAccountsResponse: APIResponse {

        public let data: [LegacyAccountModel]
    }
    
    public struct AccountsResponse: APIResponse {

        public let data: AccountModel
    }
}
