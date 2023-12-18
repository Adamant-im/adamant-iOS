//
//  CoinsNodesListStrings.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

extension String.adamant {
    enum coinsNodesList {
        static let title = String.localized("CoinsNodesList.Title", comment: .empty)
        static let serviceNode = String.localized("CoinsNodesList.ServiceNode", comment: .empty)
        static let reset = String.localized("NodesList.ResetButton", comment: .empty)
        static let resetAlert = String.localized("NodesList.ResetNodeListAlert", comment: .empty)
        
        static let preferTheFastestNode = String.localized(
            "NodesList.PreferTheFastestNode",
            comment: .empty
        )
        
        static let fastestNodeTip = String.localized(
            "NodesList.PreferTheFastestNode.Footer",
            comment: .empty
        )
    }
}
