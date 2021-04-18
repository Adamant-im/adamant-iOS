//
//  AccountsResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 12/31/17.
//

import Foundation

extension Accounts {

    public struct AccountsResponse: APIResponse {

        public let data: [AccountModel]
    }
}
