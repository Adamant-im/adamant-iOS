//
//  AdvancedAlertModel.swift
//  
//
//  Created by Andrey Golubenko on 12.04.2023.
//

import UIKit
import CommonKit

public struct AdvancedAlertModel: Equatable, Hashable {
    public let icon: UIImage
    public let title: String?
    public let text: String
    public let secondaryButton: Button?
    public let primaryButton: Button
    
    public init(
        icon: UIImage,
        title: String?,
        text: String,
        secondaryButton: Button?,
        primaryButton: Button
    ) {
        self.icon = icon
        self.title = title
        self.text = text
        self.secondaryButton = secondaryButton
        self.primaryButton = primaryButton
    }
}

public extension AdvancedAlertModel {
    struct Button: Equatable, Hashable {
        public let title: String
        public let action: IDWrapper<() -> Void>
        
        public init(title: String, action: IDWrapper<() -> Void>) {
            self.title = title
            self.action = action
        }
    }
}
