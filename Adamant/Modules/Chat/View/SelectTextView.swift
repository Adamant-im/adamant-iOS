//
//  SelectTextView.swift
//  Adamant
//
//  Created by Yana Silosieva on 13.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import SwiftUI

struct SelectTextView: View {
    var text: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextView(text: text)
                    .accentColor(.blue)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitle(String.adamant.chat.selectText, displayMode: .inline)
            .navigationBarItems(
                trailing:
                    Button(
                        action: { dismiss() }
                    ) {
                        Image(systemName: "xmark")
                    }
            )
        }
    }
}

struct TextView: UIViewRepresentable {
    var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.text = text
        textView.font = .systemFont(ofSize: 17)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
        textView.selectedTextRange = textView.textRange(
            from: textView.beginningOfDocument,
            to: textView.endOfDocument
        )
    }
}
