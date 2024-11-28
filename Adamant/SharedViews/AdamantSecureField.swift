//
//  AdamantSecureField.swift
//  Adamant
//
//  Created by Andrew G on 28.11.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI

struct AdamantSecureField: UIViewRepresentable {
    let placeholder: String?
    let text: Binding<String>
    
    func makeUIView(context _: Context) -> _View { .init() }
    
    func updateUIView(_ view: _View, context _: Context) {
        view.text = text.wrappedValue
        view.placeholder = placeholder
        view.onChanged = { [text] in text.wrappedValue = $0 ?? .empty }
    }
}

extension AdamantSecureField {
    final class _View: UITextField {
        var onChanged: (String?) -> Void = { _ in }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            configure()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }
    }
}

private extension AdamantSecureField._View {
    func configure() {
        isSecureTextEntry = true
        enablePasswordToggle()
        addTarget(self, action: #selector(_onChanged), for: .editingChanged)
    }
    
    @objc func _onChanged() {
        onChanged(text)
    }
}
