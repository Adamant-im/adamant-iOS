//
//  ServiceFeeModel.swift
//  
//
//  Created by Anton Boyarkin on 20.08.2021.
//

import Foundation

public struct ServiceFeeModel: APIModel {

    public let minFeePerByte: UInt64

    // MARK: - Hashable

    public static func == (lhs: ServiceFeeModel, rhs: ServiceFeeModel) -> Bool {
        return lhs.minFeePerByte == rhs.minFeePerByte
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(minFeePerByte)
    }

}
