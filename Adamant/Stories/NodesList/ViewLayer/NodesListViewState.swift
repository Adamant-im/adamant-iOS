//
//  NodesListViewState.swift
//  Adamant
//
//  Created by Andrey Golubenko on 31.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

struct NodesListViewState {
    var sections: [NodesSection]
    var fastestNode: Bool
    
    static let `default` = Self(sections: .init(), fastestNode: false)
}

extension NodesListViewState {
    struct NodesSection: Hashable, Equatable {
        let name: String
        var nodes: [Node]
    }
}

extension NodesListViewState.NodesSection {
    struct Node: Hashable, Equatable {
        let address: String
        var isEnabled: Bool
        let status: Status
        let ping: String
    }
}

extension NodesListViewState.NodesSection.Node {
    enum Status: Hashable, Equatable {
        case offline
        case synchronizing
        case allowed
        case `default`
    }
}
