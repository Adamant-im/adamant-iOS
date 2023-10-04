//
//  ChatMessagesViewModel.swift
//  Adamant
//
//  Created by Andrew G on 09.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import ChatKit
import CommonKit
import Combine
import Foundation
import CoreData

@MainActor
final class ChatMessagesViewModel: NSObject {
    @ObservableValue private(set) var state: ChatMessagesState = .default
    
    private let chatsProvider: ChatsProvider
    private let chatItemsListMapper: ChatItemsListMapper
    
    let chatroom: Chatroom
    
    private var controller: NSFetchedResultsController<ChatTransaction>?
    private var chatLoadingSubscription: AnyCancellable?
    private var isLoading = false
    
    nonisolated init(
        chatsProvider: ChatsProvider,
        chatItemsListMapper: ChatItemsListMapper,
        chatroom: Chatroom
    ) {
        self.chatsProvider = chatsProvider
        self.chatItemsListMapper = chatItemsListMapper
        self.chatroom = chatroom
        super.init()
        Task { @MainActor in configure() }
    }
    
    func loadMessages() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            defer { isLoading = false }
            guard await isNeededToLoadMoreMessages() else { return }
            let offset = await chatsProvider.chatLoadedMessages[partnerAddress] ?? .zero
            await chatsProvider.getChatMessages(with: partnerAddress, offset: offset)
        }
    }
}

extension ChatMessagesViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        updateTransactions()
    }
}

private extension ChatMessagesViewModel {
    var partnerAddress: String {
        chatroom.partner?.address ?? .empty
    }
    
    func configure() {
        controller = chatsProvider.getChatController(for: chatroom)
        controller?.delegate = self
        try? controller?.performFetch()
        updateTransactions()
        configureLoadingStatus()
    }
    
    func configureLoadingStatus() {
        Task {
            guard await !chatsProvider.isChatLoaded(with: partnerAddress) else { return }
            state.isInitialLoading = true
            await waitForChatLoading()
            state.isInitialLoading = false
        }
    }
    
    func updateTransactions() {
        let transactions = controller?.fetchedObjects ?? .init()
        
        Task.detached(priority: .high) { [weak self, chatItemsListMapper] in
            let messages = chatItemsListMapper.map(transactions: transactions)
            await self?.updateMessages(messages)
        }
    }
    
    func updateMessages(_ newMessages: [ChatItemModel]) {
        state.messages = newMessages
    }
    
    func isNeededToLoadMoreMessages() async -> Bool {
        let loadedCount = await chatsProvider.chatLoadedMessages[partnerAddress] ?? .zero
        let maxCount = await chatsProvider.chatMaxMessages[partnerAddress] ?? .zero
        return loadedCount < maxCount
    }
    
    func waitForChatLoading() async {
        await withUnsafeContinuation { continuation in
            Task {
                chatLoadingSubscription = await chatsProvider.chatLoadingStatusPublisher
                    .compactMap { [partnerAddress] dictionary in dictionary[partnerAddress] }
                    .filter { $0 == .loaded }
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        self?.chatLoadingSubscription = nil
                        continuation.resume()
                    }
            }
        }
    }
}
