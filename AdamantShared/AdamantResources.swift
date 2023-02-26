//
//  AdamantResources.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

struct AdamantResources {
    static let coreDataModel = Bundle.main.url(forResource: "Adamant", withExtension: "momd")!
   
    static let coinsInfoSrvice = "https://info.adamant.im"
    
    // MARK: ADAMANT Addresses
    static let supportEmail = "pr@adamant.im"
    static let ansReadmeUrl = "https://github.com/Adamant-im/adamant-notificationService"
    
    // MARK: Contacts
    struct contacts {
        static let adamantWelcomeWallet = "U00000000000000000001"
        
        static let adamantBountyWallet = "U15423595369615486571"
        static let adamantBountyWalletPK = "cdab95b082b9774bd975677c868261618c7ce7bea97d02e0f56d483e30c077b6"
        
        static let adamantNewBountyWallet = "U1835325601873095435"
        static let adamantNewBountyWalletPK = "17c03b201dc2c26f5dbb712958132c90382ab6385d674b79b8718ba1a7eb5905"
        
        static let adamantIco = "U7047165086065693428"
        static let adamantIcoPK = "1e214309cc659646ecf1d90fa37be23fe76854a76e3b4da9e4d6b65a718baf8b"
        
        static let iosSupport = "U6386412615727665758"
        static let iosSupportPK = "5b7fc59f19aff48cb56a157c2d684bf4a6ac7dfb1c8916c8e13c1c75a421c15b"
        
        static let adamantExchange = "U5149447931090026688"
        static let adamantExchangePK = "c61b50a5c72a1ee52a3060014478a5693ec69de15594a985a2b41d6f084caa9d"
        
        static let betOnBitcoin = "U17840858470710371662"
        static let betOnBitcoinPK = "ed1a7d9a8b0cd1485ae92fb78cebd45f852a24af1c983039904f765a1d581f0e"
        
        static let ansAddress = "U10629337621822775991"
        static let ansPublicKey = "188b24bd116a556ac8ba905bbbdaa16e237dfb14269f5a4f9a26be77537d977c"
        
        static let donateWallet = "U380651761819723095"
        static let donateWalletPK = "3af27b283de3ce76bdcb0d4a341208b6bc1a375c46610dfa11ca20a106ed43a8"
        
        private init() {}
    }

    private init() {}
}
