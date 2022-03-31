//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 14.03.2022.
//

import Foundation

public struct ServiceMetaFeeModel: APIModel {

    public let lastBlockHeight: UInt64

    // MARK: - Hashable

    public static func == (lhs: ServiceMetaFeeModel, rhs: ServiceMetaFeeModel) -> Bool {
        return lhs.lastBlockHeight == rhs.lastBlockHeight
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(lastBlockHeight)
    }

}
