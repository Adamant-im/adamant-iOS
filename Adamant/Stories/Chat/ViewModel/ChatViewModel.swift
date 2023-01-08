//
//  ChatViewModel.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine
import CoreData
import MarkdownKit

final class ChatViewModel: NSObject {
    // MARK: Dependencies
    
    private let chatsProvider: ChatsProvider
    private let markdownParser: MarkdownParser
    private let dialogService: DialogService
    private let transfersProvider: TransfersProvider
    
    // MARK: Properties
    
    private let _sender = ObservableProperty(Sender.default)
    private let _messages = ObservableProperty([Message]())
    private let _loadingStatus = ObservableProperty<LoadingStatus?>(nil)
    private let _inputTextSetter = ObservableProperty("")
    private let _scrollDown = ObservableSender<Void>()
    private let _showFreeTokensAlert = ObservableSender<Void>()
    
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
    
    var scrollDown: Observable<Void> {
        _scrollDown.eraseToAnyPublisher()
    }
    
    var inputTextSetter: Observable<String> {
        _inputTextSetter.eraseToAnyPublisher()
    }
    
    var showFreeTokensAlert: Observable<Void> {
        _showFreeTokensAlert.eraseToAnyPublisher()
    }
    
    var freeTokensURL: URL? {
        guard let address = chatroom?.partner?.address else { return nil }
        let urlString: String = .adamantLocalized.wallets.getFreeTokensUrl(for: address)
        
        guard let url = URL(string: urlString) else {
            dialogService.showError(
                withMessage: "Failed to create URL with string: \(urlString)",
                error: nil
            )
            return nil
        }
        
        return url
    }
    
    init(
        chatsProvider: ChatsProvider,
        markdownParser: MarkdownParser,
        dialogService: DialogService,
        transfersProvider: TransfersProvider
    ) {
        self.chatsProvider = chatsProvider
        self.markdownParser = markdownParser
        self.dialogService = dialogService
        self.transfersProvider = transfersProvider
    }
    
    func setup(
        account: AdamantAccount?,
        chatroom: Chatroom,
        messageToShow: MessageTransaction?
    ) {
        reset()
        self.chatroom = chatroom
        controller = chatsProvider.getChatController(for: chatroom)
        controller?.delegate = self
        
        guard let account = account else { return }
        _sender.value = .init(senderId: account.address, displayName: account.address)
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
    
    func sendMessage(text: String) {
        let message: AdamantMessage = markdownParser.parse(text).length == text.count
            ? .text(text)
            : .markdownText(text)
        
        guard
            let partnerAddress = chatroom?.partner?.address,
            validateSendingMessage(message: message)
        else { return }
        
        chatsProvider.sendMessage(
            message,
            recipientId: partnerAddress,
            from: chatroom
        ) { [weak self] result in
            DispatchQueue.onMainAsync {
                self?.handleMessageSendingResult(result: result, sentText: text)
            }
        }
    }
}

extension ChatViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        updateMessages()
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
        _inputTextSetter.value = ""
        controller = nil
        chatroom = nil
    }
    
    func validateSendingMessage(message: AdamantMessage) -> Bool {
        let validationStatus = chatsProvider.validateMessage(message)
        
        switch validationStatus {
        case .isValid:
            return true
        case .empty:
            return false
        case .tooLong:
            dialogService.showToastMessage(validationStatus.localized)
            return false
        }
    }
    
    func handleMessageSendingResult(result: ChatsProviderResultWithTransaction, sentText: String) {
        switch result {
        case let .success(transaction):
            guard transaction.statusEnum == .pending else { break }
            _scrollDown.send()
        case let .failure(error):
            switch error {
            case .messageNotValid:
                _inputTextSetter.value = sentText
            case .notEnoughMoneyToSend:
                _inputTextSetter.value = sentText
                guard transfersProvider.hasTransactions else {
                    _showFreeTokensAlert.send()
                    return
                }
            case .accountNotFound, .accountNotInitiated, .dependencyError, .internalError, .networkError, .notLogged, .requestCancelled, .serverError, .transactionNotFound:
                break
            }
            
            dialogService.showRichError(error: error)
        }
    }
}

private let dateHeaderTimeInterval: TimeInterval = 3600
