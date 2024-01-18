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
        static var title: String {
            String.localized("CoinsNodesList.Title", comment: .empty)
        }
        static var serviceNode: String {
            String.localized("CoinsNodesList.ServiceNode", comment: .empty)
        }
        static var reset: String {
            String.localized("NodesList.ResetButton", comment: .empty)
        }
        static var resetAlert: String {
            String.localized("NodesList.ResetNodeListAlert", comment: .empty)
        }
        
        static var preferTheFastestNode: String {
            String.localized(
                "NodesList.PreferTheFastestNode",
                comment: .empty
            )
        }
        
        static var fastestNodeTip: String {
            String.localized(
                "NodesList.PreferTheFastestNode.Footer",
                comment: .empty
            )
        }
    }
}
