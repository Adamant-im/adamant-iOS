//
//  ChatFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Swinject
import SwiftUI
import MarkdownKit

struct ChatFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([ChatAssembly()], parent: parent)
    }
    
    func makeViewController(
        chatroom: Chatroom,
        screensFactory: ScreensFactory
    ) -> AdamantChatViewController {
        .init(viewModel: .init(
            chatsProvider: assembler.resolve(ChatsProvider.self)!,
            chatItemsListMapper: assembler.resolve(ChatItemsListMapper.self)!,
            chatroom: chatroom
        ))
    }
}

private struct ChatAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ChatItemsListMapper.self) {
            .init(chatItemMapper: $0.resolve(ChatItemMapper.self)!)
        }.inObjectScope(.transient)
        
        container.register(ChatItemMapper.self) {
            let accountService = $0.resolve(AccountService.self)!
            
            return .init(
                richMessageProviders: $0.resolve([String: RichMessageProvider].self)!,
                markdownParser: MarkdownParser(
                    font: .adamantChatDefault,
                    color: .adamant.primary,
                    enabledElements: [
                        .header,
                        .list,
                        .quote,
                        .bold,
                        .italic,
                        .strikethrough
                    ],
                    customElements: [
                        MarkdownSimpleAdm(),
                        MarkdownLinkAdm(),
                        MarkdownAdvancedAdm(
                            font: .adamantChatDefault,
                            color: .adamant.active
                        ),
                        MarkdownCodeAdamant(
                            font: .adamantCodeDefault,
                            textHighlightColor: .adamant.codeBlockText,
                            textBackgroundColor: .adamant.codeBlock
                        )
                    ]
                ),
                markdownReplyParser: MarkdownParser(
                    font: .adamantChatReplyDefault,
                    color: .adamant.primary,
                    enabledElements: [
                        .header,
                        .list,
                        .quote,
                        .bold,
                        .italic,
                        .code,
                        .strikethrough
                    ],
                    customElements: [
                        MarkdownSimpleAdm(),
                        MarkdownLinkAdm(),
                        MarkdownAdvancedAdm(
                            font: .adamantChatDefault,
                            color: .adamant.active
                        )
                    ]
                ),
                avatarService: $0.resolve(AvatarService.self)!
            )
        }.inObjectScope(.transient)
        
        container.register(MarkdownParser.self) { _ in
            .init(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
        }.inObjectScope(.transient)
        
        container.register([String: RichMessageProvider].self) {
            .init(
                uniqueKeysWithValues: $0.resolve(AccountService.self)!
                    .wallets
                    .compactMap { $0 as? RichMessageProvider }
                    .map { ($0.dynamicRichMessageType, $0) }
            )
        }.inObjectScope(.transient)
    }
}
