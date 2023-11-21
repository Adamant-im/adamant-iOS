//
//  EurekaNodeRow+Model.swift
//  Adamant
//
//  Created by Andrew G on 19.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension NodeCell {
    typealias NodeUpdateAction = (_ isEnabled: Bool) -> Void
    
    struct Model: Equatable {
        let id: UUID
        let title: String
        let connectionStatus: Node.ConnectionStatus?
        let statusString: String?
        let versionString: String?
        let heightString: String?
        let isEnabled: Bool
        let activities: Set<NodeActivity>
        let nodeUpdateAction: IDWrapper<NodeUpdateAction>
        
        static let `default` = Self(
            id: .init(),
            title: .empty,
            connectionStatus: nil,
            statusString: .empty,
            versionString: .empty,
            heightString: .empty,
            isEnabled: false,
            activities: .init(),
            nodeUpdateAction: .init(id: .empty) { _ in }
        )
    }
}

extension NodeCell.Model {
    enum NodeActivity: Equatable, Hashable {
        case webSockets
        case rest(scheme: Node.URLScheme)
    }
}
