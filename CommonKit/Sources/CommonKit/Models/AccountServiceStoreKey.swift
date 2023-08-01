//
//  SecuredStore+Account.swift
//  Adamant
//
//  Created by Andrey Golubenko on 21.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

public extension StoreKey {
    enum accountService {
        public static let publicKey = "accountService.publicKey"
        public static let privateKey = "accountService.privateKey"
        public static let pin = "accountService.pin"
        public static let useBiometry = "accountService.useBiometry"
        public static let passphrase = "accountService.passphrase"
        public static let showedV12 = "accountService.showedV12"
        public static let pushTokenHash = "accountService.deviceTokenHash"
        public static let blockList = "blackList"
        public static let removedMessages = "removedMessages"
    }
}
