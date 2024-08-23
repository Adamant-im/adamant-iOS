//
//  InfoServiceMapper.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct InfoServiceMapper: InfoServiceMapperProtocol {
    func mapToModel(_ dto: InfoServiceStatusDTO) -> InfoServiceStatus {
        .init(
            lastUpdated: dto.last_updated.map {
                Date(timeIntervalSince1970: .init(milliseconds: $0))
            } ?? .adamantNullDate,
            version: .init(dto.version) ?? .zero
        )
    }
    
    func mapToModel(
        _ dto: InfoServiceResponseDTO<[String: Double]>
    ) -> InfoServiceApiResult<[String: Double]> {
        mapResponseDTO(dto)
    }
    
    func mapToModel(
        _ dto: InfoServiceResponseDTO<[InfoServiceHistoryItemDTO]>
    ) -> InfoServiceApiResult<InfoServiceHistoryItem> {
        mapResponseDTO(dto).flatMap {
            guard
                let item = $0.first,
                let ticker = item.tickers?.first?.key,
                let price = item.tickers?.first?.value
            else { return .failure(.parsingError) }
            
            return .success(.init(
                date: .init(timeIntervalSince1970: .init(milliseconds: item.date)),
                ticker: ticker,
                price: price
            ))
        }
    }
    
    func mapToNodeStatusInfo(
        ping: TimeInterval,
        status: InfoServiceStatus
    ) -> NodeStatusInfo {
        .init(
            ping: ping,
            height: Int(status.lastUpdated.timeIntervalSince1970),
            wsEnabled: false,
            wsPort: nil,
            version: status.version
        )
    }
}

private extension InfoServiceMapper {
    func mapResponseDTO<Body: Codable>(
        _ dto: InfoServiceResponseDTO<Body>
    ) -> InfoServiceApiResult<Body> {
        guard dto.success else { return .failure(.unknown) }
        return dto.result.map { .success($0) } ?? .failure(.parsingError)
    }
}
