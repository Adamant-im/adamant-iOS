//
//  UnsafeSendableAction.swift
//  CommonKit
//
//  Created by Andrew G on 09.10.2024.
//

import Foundation

public struct UnsafeSendableAction: @unchecked Sendable {
    private let action: () -> Void
    
    public init(_ action: @escaping () -> Void) {
        self.action = action
    }
    
    public func perform() {
        action()
    }
}
