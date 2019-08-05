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
    
    // MARK: Nodes
    
    static let nodes: [Node] = [
        Node(scheme: .https, host: "endless.adamant.im", port: nil),
        Node(scheme: .https, host: "clown.adamant.im", port: nil),
        Node(scheme: .https, host: "lake.adamant.im", port: nil),
//        Node(scheme: .http, host: "80.211.177.181", port: nil), // Bugged one
//        Node(scheme: .http, host: "163.172.132.38", port: 36667) // Testnet
    ]
    
    static let ethServers = [
        "https://ethnode1.adamant.im/"
//        "https://ropsten.infura.io/"  // test network
    ]
    
    static let lskServers = [
        "https://lisknode1.adamant.im"
    ]
    
    static let dogeServers: [URL] = [
        URL(string: "https://dogenode1.adamant.im/api")!
    ]
    
    static let dashServers: [URL] = [
        URL(string: "https://dashnode1.adamant.im/")!
    ]
    
    static let coinsInfoSrvice = "https://info.adamant.im"
    
    // MARK: ADAMANT Addresses
    static let supportEmail = "ios@adamant.im"
    static let ansReadmeUrl = "https://github.com/Adamant-im/AdamantNotificationService/blob/master/README.md"
    
    // MARK: Contacts
    struct contacts {
        static let adamantBountyWallet = "U15423595369615486571"
        static let adamantIco = "U7047165086065693428"
        static let iosSupport = "U15738334853882270577"
        
        static let ansAddress = "U10629337621822775991"
        static let ansPublicKey = "188b24bd116a556ac8ba905bbbdaa16e237dfb14269f5a4f9a26be77537d977c"
        
        private init() {}
    }
    
    // MARK: Explorers
    // MARK: ADM
    static let adamantExplorerAddress = "https://explorer.adamant.im/tx/"
    
    // MARK: ETH
    static let ethereumExplorerAddress = "https://etherscan.io/tx/"
    //    static let ethereumExplorerAddress = "https://ropsten.etherscan.io/tx/" // Testnet
    
    // MARK: LSK
    static let liskExplorerAddress = "https://explorer.lisk.io/tx/"
    //    static let liskExplorerAddress = "https://testnet-explorer.lisk.io/tx/" // LISK Testnet
    
    static let dogeExplorerAddress = "https://dogechain.info/tx/"
    static let dashExplorerAddress = "https://live.blockcypher.com/dash/tx/"
    
    private init() {}
}
