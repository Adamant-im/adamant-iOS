//
//  InfoServiceMapperProtocol.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

protocol InfoServiceMapperProtocol {
    func mapToModel(_ dto: InfoServiceStatusDTO) -> InfoServiceStatus
    
    func mapToModel(
        _ dto: InfoServiceResponseDTO<[String: Double]>
    ) -> InfoServiceApiResult<[String: Double]>
    
    func mapToModel(
        _ dto: InfoServiceResponseDTO<[InfoServiceHistoryItemDTO]>
    ) -> InfoServiceApiResult<InfoServiceHistoryItem>
    
    func mapToNodeStatusInfo(
        ping: TimeInterval,
        status: InfoServiceStatus
    ) -> NodeStatusInfo
}
