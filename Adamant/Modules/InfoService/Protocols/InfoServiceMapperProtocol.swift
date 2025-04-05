//
//  InfoServiceMapperProtocol.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit
import Foundation

protocol InfoServiceMapperProtocol: Sendable {
    func mapToModel(_ dto: InfoServiceStatusDTO) -> InfoServiceStatus

    func mapRatesToModel(
        _ dto: InfoServiceResponseDTO<[String: Decimal]>
    ) -> InfoServiceApiResult<[InfoServiceTicker: Decimal]>

    func mapToModel(
        _ dto: InfoServiceResponseDTO<[InfoServiceHistoryItemDTO]>
    ) -> InfoServiceApiResult<InfoServiceHistoryItem>

    func mapToNodeStatusInfo(
        ping: TimeInterval,
        status: InfoServiceStatus
    ) -> NodeStatusInfo

    func mapToRatesRequestDTO(_ coins: [String]) -> InfoServiceRatesRequestDTO

    func mapToHistoryRequestDTO(
        date: Date,
        coin: String
    ) -> InfoServiceHistoryRequestDTO
}
