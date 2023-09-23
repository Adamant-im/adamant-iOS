//
//  ChatReactionsView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 02.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit
import ElegantEmojiPicker

protocol ChatReactionsViewDelegate: AnyObject {
    func didSelectEmoji(_ emoji: String)
    func didTapMore()
}

struct ChatReactionsView: View {
    private let emojis: [String]
    private let defaultEmojis = ["😂", "🤔", "😁", "👍", "👌"]
    private let selectedEmoji: String?
    private let messageId: String
    
    var didSelectEmoji: ((_ emoji: String, _ messageId: String) -> Void)?
    var didSelectMore: (() -> Void)?
    
    init(
        emojis: [String]?,
        selectedEmoji: String?,
        messageId: String
    ) {
        self.emojis = emojis ?? defaultEmojis
        self.selectedEmoji = selectedEmoji
        self.messageId = messageId
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(emojis, id: \.self) { emoji in
                        ChatReactionButton(
                            emoji: emoji
                        )
                        .padding(.leading, 1)
                        .frame(width: 40, height: 40)
                        .background(
                            selectedEmoji == emoji
                            ? Color.init(uiColor: .gray.withAlphaComponent(0.75))
                            : .clear
                        )
                        .clipShape(Circle())
                        .onTapGesture {
                            didSelectEmoji?(emoji, messageId)
                        }
                    }
                }
            }
            .padding([.top, .bottom, .leading], 5)
            
            Button {
                didSelectMore?()
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .padding(6)
            }
            .frame(width: 30, height: 30)
            .background(Color.init(uiColor: .adamant.moreReactionsBackground))
            .clipShape(Circle())
            .padding([.top, .bottom], 5)
            Spacer()
        }
        .padding(.leading, 5)
        .background(Color.init(uiColor: .adamant.reactionsBackground))
        .cornerRadius(20)
    }
}

struct ChatReactionButton: View {
    let emoji: String
    
    var body: some View {
        Text(emoji)
            .font(.title)
            .clipShape(Circle())
    }
}
