//
//  AdamantResources.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

enum AdamantResources {
    static let coreDataModel = storeURL(appGroup: appGroup, databaseName: "Adamant")
    
#if DEBUG
    static let appGroup = "group.adamant.adamant-messenger-dev"
#else
    static let appGroup = "group.adamant.adamant-messenger"
#endif
    
    static let coinsInfoSrvice = "https://info.adamant.im"
    
    // MARK: ADAMANT Addresses
    static let supportEmail = "business@adamant.im"
    static let ansReadmeUrl = "https://github.com/Adamant-im/adamant-notificationService"
    
    // MARK: Contacts
    enum contacts {
        static let adamantWelcomeWallet = "U00000000000000000001"
        
        static let adamantBountyWallet = "U15423595369615486571"
        static let adamantBountyWalletPK = "cdab95b082b9774bd975677c868261618c7ce7bea97d02e0f56d483e30c077b6"
        
        static let adamantNewBountyWallet = "U1835325601873095435"
        static let adamantNewBountyWalletPK = "17c03b201dc2c26f5dbb712958132c90382ab6385d674b79b8718ba1a7eb5905"
        
        static let adamantIco = "U7047165086065693428"
        static let adamantIcoPK = "1e214309cc659646ecf1d90fa37be23fe76854a76e3b4da9e4d6b65a718baf8b"
        
        static let adamantSupport = "U14077334060470162548"
        static let adamantSupportPK = "824991512e52aa69885df8c79d64cddee9781737d10f36636bf2cf589b7e166a"
        
        static let adamantExchange = "U5149447931090026688"
        static let adamantExchangePK = "c61b50a5c72a1ee52a3060014478a5693ec69de15594a985a2b41d6f084caa9d"
        
        static let betOnBitcoin = "U17840858470710371662"
        static let betOnBitcoinPK = "ed1a7d9a8b0cd1485ae92fb78cebd45f852a24af1c983039904f765a1d581f0e"
        
        static let ansAddress = "U10629337621822775991"
        static let ansPublicKey = "188b24bd116a556ac8ba905bbbdaa16e237dfb14269f5a4f9a26be77537d977c"
        
        static let donateWallet = "U380651761819723095"
        static let donateWalletPK = "3af27b283de3ce76bdcb0d4a341208b6bc1a375c46610dfa11ca20a106ed43a8"
        
        static let adelinaWallet = "U11138426591213238985"
        static let adelinaWalletPK = "8e06eba03ebe4668148647fc00a64b3fae59a1911ce1fd1059baba39ceb705a4"
        
        static let pwaBountyBot = "U1644771796259136854"
        static let pwaBountyBotPK = "7a5c55dec7a085f1c795a126b3f74ebdccf36b7abfa2f85145443e58fcdff80c"
    }
}

private extension AdamantResources {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(appGroup: String, databaseName: String) -> URL {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
            .appendingPathComponent("\(databaseName).sqlite")
    }
}
