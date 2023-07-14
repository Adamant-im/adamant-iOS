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
                            emoji: emoji
                        )
                        .padding([.leading], 1)
                        .frame(width: 40, height: 40)
                        .background(
                            selectedEmoji == emoji
                            ? Color.init(uiColor: .adamant.active)
                            : .clear
                        )
                        .clipShape(Circle())
                        .onTapGesture {
                            delegate?.didSelectEmoji(emoji)
                        }
                    }
                }
            }
            .padding([.top, .bottom, .leading], 5)
            
            Button {
                delegate?.didTapMore()
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(5)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding([.top, .bottom], 5)
            Spacer()
        }
        .padding(.leading, 5)
        .background(Color.init(uiColor: .adamant.codeBlock))
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
