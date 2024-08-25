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
    
    func mapRatesToModel(
        _ dto: InfoServiceResponseDTO<[String: String]>
    ) -> InfoServiceApiResult<[InfoServiceTicker: Decimal]> {
        mapResponseDTO(dto).map { mapToTickers($0) }
    }
    
    func mapToModel(
        _ dto: InfoServiceResponseDTO<[InfoServiceHistoryItemDTO]>
    ) -> InfoServiceApiResult<InfoServiceHistoryItem> {
        mapResponseDTO(dto).flatMap {
            guard
                let item = $0.first,
                let tickers = item.tickers
            else { return .failure(.parsingError) }
            
            return .success(.init(
                date: .init(timeIntervalSince1970: .init(milliseconds: item.date)),
                tickers: mapToTickers(tickers)
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
    
    func mapToRatesRequestDTO(_ coins: [String]) -> InfoServiceRatesRequestDTO {
        .init(coin: coins.joined(separator: ","))
    }
    
    func mapToHistoryRequestDTO(
        date: Date,
        coin: String
    ) -> InfoServiceHistoryRequestDTO {
        .init(
            timestamp: .init(format: "%.0f", date.timeIntervalSince1970),
            coin: coin
        )
    }
}

private extension InfoServiceMapper {
    func mapToTickers(_ rawTickers: [String: String]) -> [InfoServiceTicker: Decimal] {
        .init(uniqueKeysWithValues: rawTickers.compactMap { key, value in
            guard
                let ticker = mapToTicker(key),
                let price = Decimal(string: value)
            else { return nil }
            
            return (ticker, price)
        })
    }
    
    func mapToTicker(_ string: String) -> InfoServiceTicker? {
        let list: [String] = string.split(separator: "/").map { .init($0) }
        
        guard
            list.count == 2,
            let crypto = list.first,
            let fiat = list.last
        else { return nil }
        
        return .init(crypto: crypto, fiat: fiat)
    }
    
    func mapResponseDTO<Body: Codable>(
        _ dto: InfoServiceResponseDTO<Body>
    ) -> InfoServiceApiResult<Body> {
        guard dto.success else { return .failure(.unknown) }
        return dto.result.map { .success($0) } ?? .failure(.parsingError)
    }
}
