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
    private let emojiRanges = [0x1F601...0x1F64F]
    
    private let emojies: [String]
    private weak var delegate: ChatReactionsViewDelegate?
    
    init(delegate: ChatReactionsViewDelegate?) {
        self.delegate = delegate
        self.emojies = ["😂", "🤔", "😁", "👍", "👌"]
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ChatReactionEreaserButton()
                        .onTapGesture {
                            delegate?.didSelectEmoji("")
                        }
                    ForEach(emojies, id: \.self) { emoji in
                        ChatReactionButton(emoji: emoji)
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
    
    var body: some View {
        Text(emoji)
            .font(.title)
            .background(.clear)
            .clipShape(Circle())
    }
}

struct ChatReactionEreaserButton: View {
    var body: some View {
        Image(systemName: "eraser")
            .font(.title)
            .background(.clear)
            .clipShape(Circle())
    }
}
