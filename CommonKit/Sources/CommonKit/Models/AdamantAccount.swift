//
//  Account.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public struct AdamantAccount: @unchecked Sendable {
    public let address: String
    public var unconfirmedBalance: Decimal
    public var balance: Decimal
    public var publicKey: String?
    public let unconfirmedSignature: Int
    public let secondSignature: Int
    public let secondPublicKey: String?
    public let multisignatures: [String]?
    public let uMultisignatures: [String]?
    public var isDummy: Bool
    
    public init(
        address: String,
        unconfirmedBalance: Decimal,
        balance: Decimal, 
        publicKey: String?,
        unconfirmedSignature: Int,
        secondSignature: Int,
        secondPublicKey: String?,
        multisignatures: [String]?,
        uMultisignatures: [String]?,
        isDummy: Bool
    ) {
        self.address = address
        self.unconfirmedBalance = unconfirmedBalance
        self.balance = balance
        self.publicKey = publicKey
        self.unconfirmedSignature = unconfirmedSignature
        self.secondSignature = secondSignature
        self.secondPublicKey = secondPublicKey
        self.multisignatures = multisignatures
        self.uMultisignatures = uMultisignatures
        self.isDummy = isDummy
    }
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
    
    public init(from decoder: Decoder) throws {
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
        self.isDummy = false
    }
}

extension AdamantAccount: WrappableModel {
    public static let ModelKey = "account"
    
    public static func makeEmptyAccount(publicKey: String) -> Self {
        .init(
            address: AdamantUtilities.generateAddress(publicKey: publicKey),
            unconfirmedBalance: .zero,
            balance: .zero,
            publicKey: publicKey,
            unconfirmedSignature: .zero,
            secondSignature: .zero,
            secondPublicKey: nil,
            multisignatures: nil,
            uMultisignatures: nil,
            isDummy: false
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
