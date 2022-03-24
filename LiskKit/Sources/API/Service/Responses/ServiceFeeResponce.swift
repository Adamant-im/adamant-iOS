//
//  ServiceFeeResponse.swift
//  
//
//  Created by Anton Boyarkin on 20.08.2021.
//

import Foundation

public struct ServiceFeeResponse: APIResponse {

    public let data: ServiceFeeModel
    public let meta: ServiceMetaFeeModel
}
