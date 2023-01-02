//
//  ChatViewModel.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine
import CoreData

final class ChatViewModel: NSObject {
    // MARK: Dependencies
    
    private let chatsProvider: ChatsProvider
    
    // MARK: Properties
    
    private let _sender = ObservableProperty(Sender.default)
    private let _messages = ObservableProperty([Message]())
    private let _loadingStatus = ObservableProperty<LoadingStatus?>(nil)
    
    private var controller: NSFetchedResultsController<ChatTransaction>?
    private var account: AdamantAccount?
    private var messageToShow: MessageTransaction?
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
        self.account = account
        self.chatroom = chatroom
        self.messageToShow = messageToShow
        controller = chatsProvider.getChatController(for: chatroom)
    }
    
    func loadMessages() {
        guard let address = chatroom?.partner?.address else { return }
        
        chatsProvider.getChatMessages(with: address, offset: .zero) { [weak self] in
            DispatchQueue.onMainAsync { self?.updateMessages() }
        }
    }
    
    func isNeedToDisplayDateHeader(index: Int) -> Bool {
        guard index > .zero else { return true }
        
        let timeIntervalFromLastMessage = messages.value[index].sentDate
            .timeIntervalSince(messages.value[index - 1].sentDate)
        
        return timeIntervalFromLastMessage >= dateHeaderTimeInterval
    }
}

private extension ChatViewModel {
    func updateMessages() {
        try? controller?.performFetch()
        _messages.value = (controller?.fetchedObjects ?? []).map {
            .init(chatTransaction: $0)
        }
    }
    
    func setIsLoading(_ isLoading: Bool) {
        _loadingStatus.value = isLoading
            ? messages.value.count == .zero
                ? .fullscreen
                : .onTop
            : nil
    }
}

private let dateHeaderTimeInterval: TimeInterval = 3600
