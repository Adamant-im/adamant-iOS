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
        self.emojies = emojiRanges.flatMap { range in
            range.compactMap { i in
                guard let scalar = UnicodeScalar(i) else { return nil }
                return String(scalar)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            HStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
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
                        .shadow(radius: 3)
                }
                Spacer()
            }
            Spacer()
        }
        .frame(alignment: .center)
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
            .shadow(radius: 3)
    }
}
