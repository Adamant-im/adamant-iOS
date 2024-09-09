//
//  NodeType.swift
//
//
//  Created by Andrew G on 01.08.2024.
//

public enum NodeType: Codable, Equatable {
    case custom
    case `default`(isHidden: Bool)
}
