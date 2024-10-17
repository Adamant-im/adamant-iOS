//
//  EurekaNodeRow+Model.swift
//  Adamant
//
//  Created by Andrew G on 19.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension NodeCell {
    typealias NodeUpdateAction = (_ isEnabled: Bool) -> Void
    
    struct Model: Equatable {
        let id: UUID
        let title: String
        let indicatorString: String
        let indicatorColor: UIColor
        let statusString: String
        let isEnabled: Bool
        let nodeUpdateAction: IDWrapper<NodeUpdateAction>
        
        static var `default`: Self {
            Self(
                id: .init(),
                title: .empty,
                indicatorString: .init(),
                indicatorColor: .adamant.inactive,
                statusString: .empty,
                isEnabled: false,
                nodeUpdateAction: .init(id: .empty) { _ in }
            )
        }
    }
}
