//
//  SecuredStore+Account.swift
//  Adamant
//
//  Created by Andrey Golubenko on 21.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

extension StoreKey {
    enum accountService {
        static let publicKey = "accountService.publicKey"
        static let privateKey = "accountService.privateKey"
        static let pin = "accountService.pin"
        static let useBiometry = "accountService.useBiometry"
        static let passphrase = "accountService.passphrase"
        static let showedV12 = "accountService.showedV12"
        static let pushTokenHash = "accountService.deviceTokenHash"
        static let blackList = "blackList"
        static let removedMessages = "removedMessages"
    }
}
