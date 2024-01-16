//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 18.12.2023.
//

import Foundation

public struct Block: Decodable {
    public let header: Header
}

public struct Header: Decodable {
    public let version: Int
    public let timestamp: Int
    public let height: Int
    public let previousBlockID: String
    public let stateRoot: String
    public let assetRoot: String
    public let eventRoot: String
    public let transactionRoot: String
    public let validatorsHash: String
    public let generatorAddress: String
    public let maxHeightPrevoted: Int
    public let maxHeightGenerated: Int
    public let signature: String
    public let id: String
}

/*
 {
    "header": {
       "version": 2,
       "timestamp": 1660665257,
       "height": 5557,
       "previousBlockID": "0b3805615011809f00d5fb2c3242674ffdf29a689937427c0b647f7acd8a7a24",
       "stateRoot": "abb3d47a904d2d2671331fc015960d58eda504255ac5249b33af46e8e5a0c4f2",
       "assetRoot": "9a1b203ef3a32c41ed18a04ee9d9fb6cda4b9ade88dd85e7dd74e072c25d3381",
       "eventRoot": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
       "transactionRoot": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
       "validatorsHash": "ad0076aa444f6cda608bb163c3bd77d9bf172f1d2803d53095bc0f277db6bcb3",
       "aggregateCommit": {
             "height": 5405,
             "aggregationBits": "",
             "certificateSignature": ""
       },
       "generatorAddress": "635bbf383c03b2e986521c2d725e9f71dd651054",
       "maxHeightPrevoted": 5489,
       "maxHeightGenerated": 5401,
       "signature": "45d8a977127d09923d336ce7e60151ff74b8b299f91f5760610c5ce16fa88c44a4c8fd1e651ea443f82ae460a110f7bb0e7f9eccbe5dc8f5d29268a308bcdc06",
       "id": "6c4734053d0c9822db98c857946a07b980c684a05b33536cb6cf069e861c26e7"
    },
    "transactions": [],
    "assets": [
       {
             "moduleID": "0000000f",
             "data": "0a10c6a94fa0d336c0fe57d37098222ff2e3"
       }
    ]
 }
 */
