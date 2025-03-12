//
//  PasteInterceptingTextField.swift
//  Adamant
//
//  Created by Christian Benua on 23.02.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit

final class PasteInterceptingTextField: UITextField, UITextFieldDelegate {
    
    private var isAfterPaste: Bool = false
    var pasteInterceptor: ((String?) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePasteNotification),
            name: UITextField.textDidChangeNotification,
            object: self
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func paste(_ sender: Any?) {
        isAfterPaste = true
        super.paste(sender)
    }
    
    @objc func handlePasteNotification() {
        if isAfterPaste {
            pasteInterceptor?(text)
        }
        isAfterPaste = false
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if isAfterPaste {
            pasteInterceptor?(textField.text)
        }
        
        isAfterPaste = false
        return true
    }
}
