//
//  Account.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct AdamantAccount {
    let address: String
    var unconfirmedBalance: Decimal
    var balance: Decimal
    let publicKey: String?
    let unconfirmedSignature: Int
    let secondSignature: Int
    let secondPublicKey: String?
    let multisignatures: [String]?
    let uMultisignatures: [String]?
}

extension AdamantAccount: Decodable {
    enum CodingKeys: String, CodingKey {
        case address
        case unconfirmedBalance
        case balance
        case publicKey
        case unconfirmedSignature
        case secondSignature
        case secondPublicKey
        case multisignatures
        case uMultisignatures = "u_multisignatures"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.address = try container.decode(String.self, forKey: .address)
        self.unconfirmedSignature = try container.decode(Int.self, forKey: .unconfirmedSignature)
        self.publicKey = try? container.decode(String.self, forKey: .publicKey)
        self.secondSignature = try container.decode(Int.self, forKey: .secondSignature)
        self.secondPublicKey = try? container.decode(String.self, forKey: .secondPublicKey)
        self.multisignatures = try? container.decode([String].self, forKey: .multisignatures)
        self.uMultisignatures = try? container.decode([String].self, forKey: .uMultisignatures)
        
        let unconfirmedBalance = Decimal(string: try container.decode(String.self, forKey: .unconfirmedBalance))!
        self.unconfirmedBalance = unconfirmedBalance.shiftedFromAdamant()
        let balance = Decimal(string: try container.decode(String.self, forKey: .balance))!
        self.balance = balance.shiftedFromAdamant()
    }
}

extension AdamantAccount: WrappableModel {
    static let ModelKey = "account"
    
    static func makeEmptyAccount(publicKey: String) -> Self {
        .init(
            address: AdamantUtilities.generateAddress(publicKey: publicKey),
            unconfirmedBalance: .zero,
            balance: .zero,
            publicKey: publicKey,
            unconfirmedSignature: .zero,
            secondSignature: .zero,
            secondPublicKey: nil,
            multisignatures: nil,
            uMultisignatures: nil
        )
    }
}

// MARK: - JSON
/*
{
    "address": "U2279741505997340299",
    "unconfirmedBalance": "49000000",
    "balance": "49000000",
    "publicKey": "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
    "unconfirmedSignature": 0,
    "secondSignature": 0,
    "secondPublicKey": null,
    "multisignatures": [
    ],
    "u_multisignatures": [
    ]
}
*/
