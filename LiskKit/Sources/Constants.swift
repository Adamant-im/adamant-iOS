//
//  Constants.swift
//  Lisk
//
//  Created by Andrew Barba on 12/26/17.
//

import Foundation

/// API Constants copied from:
/// https://github.com/LiskHQ/lisk-js/blob/1.0.0/src/constants.js
public struct Constants {

    public static let version = "1.0.0"

    public static let fixedPoint: Double = pow(10, 8)

    public struct Fee {
        public static let transfer = UInt64(0.1 * fixedPoint)
        public static let data = UInt64(0.1 * fixedPoint)
        public static let inTransfer = UInt64(0.1 * fixedPoint)
        public static let outTransfer = UInt64(0.1 * fixedPoint)
        public static let signature = UInt64(5 * fixedPoint)
        public static let delegate = UInt64(25 * fixedPoint)
        public static let vote = UInt64(1 * fixedPoint)
        public static let multisignature = UInt64(5 * fixedPoint)
        public static let dapp = UInt64(25 * fixedPoint)
    }

    public struct Time {
        public static let epochMilliseconds: Double = 1464109200000
        public static let epochSeconds: TimeInterval = epochMilliseconds / 1000
        public static let epoch: Date = Date(timeIntervalSince1970: epochSeconds)
    }

    public struct Nethash {
        public static let main = "ed14889723f24ecc54871d058d98ce91ff2f973192075c0155ba2b7b70ad2511"
        public static let test = "da3ed6a45429278bac2666961289ca17ad86595d33b31037615d4b8e8f158bba"
        public static let beta = "ef3844327d1fd0fc5785291806150c937797bdb34a748c9cd932b7e859e9ca0c"
    }
}
