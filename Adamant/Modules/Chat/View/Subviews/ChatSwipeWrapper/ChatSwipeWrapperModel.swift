//
//  ChatSwipeWrapperModel.swift
//  Adamant
//
//  Created by Andrew G on 16.12.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CoreGraphics

struct ChatSwipeWrapperModel: Identifiable, Equatable {
    let id: String
    var state: State
    
    static let `default` = Self(id: .empty, state: .idle)
}

extension ChatSwipeWrapperModel {
    enum State: Equatable {
        case idle
        case offset(CGFloat)
    }
}

extension ChatSwipeWrapperModel.State {
    var value: CGFloat {
        switch self {
        case .idle:
            .zero
        case let .offset(value):
            value
        }
    }
}
