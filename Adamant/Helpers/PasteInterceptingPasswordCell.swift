//
//  PasteInterceptingPasswordCell.swift
//  Adamant
//
//  Created by Christian Benua on 23.02.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit
import Eureka

final class PasteInterceptingPasswordCell: CustomFieldCell<String, PasteInterceptingTextField>, CellType {
    
    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .asciiCapable
        textField.isSecureTextEntry = true
        textField.textContentType = .password
        if let textLabel = textLabel {
            textField.setContentHuggingPriority(textLabel.contentHuggingPriority(for: .horizontal) - 1, for: .horizontal)
        }
    }
}
