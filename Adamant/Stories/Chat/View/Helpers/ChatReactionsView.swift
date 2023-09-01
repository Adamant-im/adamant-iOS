//
//  ChatReactionsView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 02.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit
import MCEmojiPicker

protocol ChatReactionsViewDelegate: AnyObject {
    func didSelectEmoji(_ emoji: String)
    func didTapMore()
}

struct ChatReactionsView: View {
    private let emojis: [String]
    private weak var delegate: ChatReactionsViewDelegate?
    private let defaultEmojis = ["😂", "🤔", "😁", "👍", "👌"]
    private let selectedEmoji: String?
    private let messageId: String
    
    @SwiftUI.State private var isPresentedMore: Bool = false
    @SwiftUI.State private var selectedEmojiMore: String = ""
    
    var didSelectEmoji: ((_ emoji: String, _ messageId: String) -> Void)?
    
    init(
        delegate: ChatReactionsViewDelegate?,
        emojis: [String]?,
        selectedEmoji: String?,
        messageId: String
    ) {
        self.delegate = delegate
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
                isPresentedMore.toggle()
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .padding(6)
            }
            .emojiPicker(
                isPresented: $isPresentedMore,
                selectedEmoji: $selectedEmojiMore
            )
            .onChange(of: selectedEmojiMore, perform: { newValue in
                didSelectEmoji?(newValue, messageId)
            })
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
