//
//  ChatViewModel.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine
import CoreData

final class ChatViewModel {
    // MARK: Dependencies
    
    private let chatsProvider: ChatsProvider
    
    // MARK: Properties
    
    private let _sender = ObservableProperty(Sender.default)
    private let _messages = ObservableProperty([Message]())
    private let _loadingStatus = ObservableProperty<LoadingStatus?>(nil)
    
    private var controller: NSFetchedResultsController<ChatTransaction>?
    private(set) var chatroom: Chatroom?
    
    var sender: ObservableVariable<Sender> {
        _sender.eraseToGetter()
    }
    
    var messages: ObservableVariable<[Message]> {
        _messages.eraseToGetter()
    }
    
    var loadingStatus: ObservableVariable<LoadingStatus?> {
        _loadingStatus.eraseToGetter()
    }
    
    init(chatsProvider: ChatsProvider) {
        self.chatsProvider = chatsProvider
    }
    
    func setup(
        account: AdamantAccount?,
        chatroom: Chatroom,
        messageToShow: MessageTransaction?
    ) {
        reset()
        self.chatroom = chatroom
        controller = chatsProvider.getChatController(for: chatroom)
        
        guard let account = account else { return }
        _sender.value = .init(senderId: account.address, displayName: account.address)
        _messages.value = []
    }
    
    func loadFirstMessages() {
        guard let address = chatroom?.partner?.address else { return }
        
        if address == AdamantContacts.adamantWelcomeWallet.name {
            updateMessages()
        } else {
            loadMessages(address: address, offset: .zero, loadingStatus: .fullscreen)
        }
    }
    
    func loadMoreMessagesIfNeeded() {
        guard
            let address = chatroom?.partner?.address,
            chatsProvider.chatMaxMessages[address] ?? .zero > messages.value.count
        else { return }
        
        loadMessages(address: address, offset: messages.value.count, loadingStatus: .onTop)
    }
    
    func isNeedToDisplayDateHeader(index: Int) -> Bool {
        guard index > .zero else { return true }
        
        let timeIntervalFromLastMessage = messages.value[index].sentDate
            .timeIntervalSince(messages.value[index - 1].sentDate)
        
        return timeIntervalFromLastMessage >= dateHeaderTimeInterval
    }
}

private extension ChatViewModel {
    var isLoading: Bool {
        switch loadingStatus.value {
        case .fullscreen, .onTop:
            return true
        case .none:
            return false
        }
    }
    
    func loadMessages(address: String, offset: Int, loadingStatus: LoadingStatus) {
        guard !isLoading else { return }
        
        _loadingStatus.value = loadingStatus
        chatsProvider.getChatMessages(
            with: address,
            offset: offset
        ) { [weak self] in
            DispatchQueue.onMainAsync {
                self?.updateMessages()
                self?._loadingStatus.value = nil
            }
        }
    }
    
    func updateMessages() {
        try? controller?.performFetch()
        _messages.value = (controller?.fetchedObjects ?? []).map {
            .init(chatTransaction: $0)
        }
    }
    
    func reset() {
        _sender.value = .default
        _messages.value = []
        _loadingStatus.value = nil
        controller = nil
        chatroom = nil
    }
}

private let dateHeaderTimeInterval: TimeInterval = 3600
