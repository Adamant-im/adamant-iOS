//
//  ChatReactionsView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 02.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import ElegantEmojiPicker
import SwiftUI

protocol ChatReactionsViewDelegate: AnyObject {
    func didSelectEmoji(_ emoji: String)
    func didTapMore()
}

struct ChatReactionsView: View {
    private let emojis: [String]
    private let defaultEmojis = ["😂", "🤔", "😁", "👍", "👌", "🤝"]
    private let selectedEmoji: String?
    private let messageId: String

    var didSelectEmoji: ((_ emoji: String, _ messageId: String) -> Void)?
    var didSelectMore: (() -> Void)?
    
    @State private var isPlusHovered = false

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
                HStack(spacing: 5) {
                    ForEach(emojis.prefix(6), id: \.self) { emoji in
                        ChatReactionButton(
                            emoji: emoji,
                            isSelected: selectedEmoji == emoji
                        )
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
            .background(
                isPlusHovered
                ? Color.init(uiColor: .adamant.contextMenuSelectColor)
                : Color.init(uiColor: .adamant.moreReactionsBackground)
            )
            .clipShape(Circle())
            .scaleEffect(isPlusHovered ? 1.15 : 1.0)
            .onHover { hovering in
                isPlusHovered = hovering
            }
            .animation(.easeInOut(duration: 0.2), value: isPlusHovered)
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
    let isSelected: Bool
    
    @State private var isHovered = false

    var body: some View {
        Text(emoji)
            .font(.title)
            .frame(width: 40, height: 40)
            .background( isHovered ? Color.init(uiColor: .adamant.contextMenuSelectColor) :
                            (isSelected ? Color.init(uiColor: .gray.withAlphaComponent(0.75)) : Color.clear))
            .clipShape(Circle())
            .onHover { hovering in
                isHovered = hovering
            }
            .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}
