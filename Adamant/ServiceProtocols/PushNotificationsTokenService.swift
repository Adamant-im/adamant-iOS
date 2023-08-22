//
//  PushNotificationsTokenService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension StoreKey {
    enum PushNotificationsTokenService {
        static let token = "pushNotifications.token"
        static let tokenDeletionTransactions = "pushNotifications.tokenDeletionTransactions"
    }
}

protocol PushNotificationsTokenService: AnyObject {
    func setToken(_ token: Data)
    func removeCurrentToken()
    func sendTokenDeletionTransactions()
}
