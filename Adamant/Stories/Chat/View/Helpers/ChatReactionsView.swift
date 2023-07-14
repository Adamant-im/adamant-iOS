//
//  ChatReactionsView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 02.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

protocol ChatReactionsViewDelegate: AnyObject {
    func didSelectEmoji(_ emoji: String)
    func didTapMore()
}

struct ChatReactionsView: View {
    private var emojis: [String]
    private weak var delegate: ChatReactionsViewDelegate?
    private let defaultEmojis = ["😂", "🤔", "😁", "👍", "👌"]
    private let selectedEmoji: String?
    
    init(
        delegate: ChatReactionsViewDelegate?,
        emojis: [String]?,
        selectedEmoji: String?
    ) {
        self.delegate = delegate
        self.emojis = emojis ?? defaultEmojis
        self.selectedEmoji = selectedEmoji
        
        if let selectedEmoji = selectedEmoji,
           !self.emojis.contains(selectedEmoji) {
            self.emojis.insert(selectedEmoji, at: 0)
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(emojis, id: \.self) { emoji in
                        ChatReactionButton(
                            emoji: emoji,
                            isSelected: selectedEmoji == emoji
                        )
                        .onTapGesture {
                            delegate?.didSelectEmoji(emoji)
                        }
                    }
                }
            }
            
            Button {
                delegate?.didTapMore()
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding(5)
            Spacer()
        }
        .padding(.leading, 10)
        .background(Color.init(uiColor: .adamant.codeBlock))
        .cornerRadius(20)
    }
}

struct ChatReactionButton: View {
    let emoji: String
    let isSelected: Bool
    
    var body: some View {
        Text(emoji)
            .font(.title)
            .background(isSelected ? Color.gray : .clear)
            .clipShape(Circle())
    }
}
