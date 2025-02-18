//
//  CoinsNodesListState.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct CoinsNodesListState: Equatable {
    var sections: [Section]
    var fastestNodeMode: Bool
    var isAlertShown: Bool
    
    static var `default`: Self {
        Self(
            sections: .init(),
            fastestNodeMode: false,
            isAlertShown: false
        )
    }
}

extension CoinsNodesListState {
    struct Section: Equatable, Identifiable {
        let id: NodeGroup
        let title: String
        let rows: [Row]
    }
}

extension CoinsNodesListState.Section {
    struct Row: Equatable, Identifiable {
        let id: UUID
        let group: NodeGroup
        let isEnabled: Bool
        let title: AttributedString
        let connectionStatus: AttributedString
        let subtitle: AttributedString
    }
}
