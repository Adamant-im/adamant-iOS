//
//  AdamantTransactionsService.swift
//  CommonKit
//
//  Created by Sergei Veretennikov on 21.02.2025.
//

import Foundation
import UIKit

public protocol AdamantTransactionsService: AnyObject {
    func getChatRooms(
        address: String,
        offset: Int?,
        waitsForConnectivity: Bool
    ) async -> ApiServiceResult<ChatRooms>
}

final public class AdamantTransactionServiceImpl: AdamantTransactionsService {
    public let service: BlockchainHealthCheckWrapper<AdamantApiCore>
    
    public init(
        healthCheckWrapper: BlockchainHealthCheckWrapper<AdamantApiCore>
    ) {
        service = healthCheckWrapper
    }
    
    public func getChatRooms(
        address: String,
        offset: Int?,
        waitsForConnectivity: Bool
    ) async -> ApiServiceResult<ChatRooms> {
        var parameters = ["limit": "20"]
        
        if let offset = offset {
            parameters["offset"] = String(offset)
        }
        
        return await request(waitsForConnectivity: waitsForConnectivity) {
            [parameters] service, origin in
            await service.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Chats.getChatRooms + "/\(address)",
                method: .get,
                parameters: parameters,
                encoding: .url
            )
        }
    }
    
    public func request<Output>(
        waitsForConnectivity: Bool = false,
        _ request: @Sendable (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> ApiServiceResult<Output> {
        await service.request(
            waitsForConnectivity: waitsForConnectivity
        ) { admApiCore, origin in
            await request(admApiCore.apiCore, origin)
        }
    }
}
