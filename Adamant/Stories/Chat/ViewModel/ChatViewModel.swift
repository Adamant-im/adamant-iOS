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
    private let chatMessageFactory: ChatMessageFactory
    let richMessageProviders: [String: RichMessageProvider]
    
    // MARK: Properties
    
    private let _sender = ObservableProperty(ChatSender.default)
    private let _messages = ObservableProperty([ChatMessage]())
    private let _loadingStatus = ObservableProperty<ChatLoadingStatus?>(nil)
    private let _scrollDown = ObservableSender<Void>()
    private let _showFreeTokensAlert = ObservableSender<Void>()
    private let _isSendingAvailable = ObservableProperty(false)
    private let _messageIdToShow = ObservableProperty<String?>(nil)
    private let _fee = ObservableProperty("")
    
    private weak var preservationDelegate: ChatPreservationDelegate?
    private var controller: NSFetchedResultsController<ChatTransaction>?
    private(set) var chatroom: Chatroom?
    private var subscriptions = Set<AnyCancellable>()
    
    private(set) var chatTransactions: [ChatTransaction] = [] {
        didSet { _messages.value = chatTransactions.map(chatMessageFactory.makeMessage) }
    }
    
    let inputText = ObservableProperty("")
    let didTapTransfer = ObservableSender<String>()
    
    var sender: ObservableVariable<ChatSender> {
        _sender.eraseToGetter()
    }
    
    var messages: ObservableVariable<[ChatMessage]> {
        _messages.eraseToGetter()
    }
    
    var loadingStatus: ObservableVariable<ChatLoadingStatus?> {
        _loadingStatus.eraseToGetter()
    }
    
    var scrollDown: Observable<Void> {
        _scrollDown.eraseToAnyPublisher()
    }
    
    var showFreeTokensAlert: Observable<Void> {
        _showFreeTokensAlert.eraseToAnyPublisher()
    }
    
    var isSendingAvailable: ObservableVariable<Bool> {
        _isSendingAvailable.eraseToGetter()
    }
    
    var messageIdToShow: Observable<String?> {
        _messageIdToShow.eraseToAnyPublisher()
    }
    
    var fee: ObservableVariable<String> {
        _fee.eraseToGetter()
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
        transfersProvider: TransfersProvider,
        chatMessageFactory: ChatMessageFactory,
        richMessageProviders: [String: RichMessageProvider]
    ) {
        self.chatsProvider = chatsProvider
        self.markdownParser = markdownParser
        self.dialogService = dialogService
        self.transfersProvider = transfersProvider
        self.chatMessageFactory = chatMessageFactory
        self.richMessageProviders = richMessageProviders
        super.init()
        setupObservers()
    }
    
    func setup(
        account: AdamantAccount?,
        chatroom: Chatroom,
        messageToShow: MessageTransaction?,
        preservationDelegate: ChatPreservationDelegate?
    ) {
        reset()
        self.chatroom = chatroom
        self.preservationDelegate = preservationDelegate
        controller = chatsProvider.getChatController(for: chatroom)
        controller?.delegate = self
        _isSendingAvailable.value = !chatroom.isReadonly
        _messageIdToShow.value = messageToShow?.chatMessageId
        
        if let account = account {
            _sender.value = .init(senderId: account.address, displayName: account.address)
        }
        
        if let partnerAddress = chatroom.partner?.address {
            chatsProvider.chatPositon.removeValue(forKey: partnerAddress)
            
            let message = preservationDelegate?.getPreservedMessageFor(
                address: partnerAddress,
                thenRemoveIt: true
            )
            
            message.map { inputText.value = $0 }
        }
    }
    
    func loadFirstMessages() {
        guard let address = chatroom?.partner?.address else { return }
        
        if address == AdamantContacts.adamantWelcomeWallet.name {
            updateMessages(performFetch: true)
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
    
    func isNeedToDisplayDateHeader(sentDate: Date, index: Int) -> Bool {
        guard sentDate != .adamantNullDate else { return false }
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
    
    func updateTransactionStatusIfNeeded(id: String) {
        guard
            let transaction = chatTransactions.first(where: { $0.chatMessageId == id }),
            let richMessageTransaction = transaction as? RichMessageTransaction,
            !(richMessageTransaction.transactionStatus?.isFinal ?? false)
        else { return }
        
        chatsProvider.updateStatus(for: richMessageTransaction)
    }
    
    func preserveMessage(_ message: String) {
        guard let partnerAddress = chatroom?.partner?.address else { return }
        preservationDelegate?.preserveMessage(message, forAddress: partnerAddress)
    }
    
    func showDublicatedTransactionAlert() {
        dialogService.showAlert(
            title: nil,
            message: .adamantLocalized.sharedErrors.duplicatedTransaction,
            style: AdamantAlertStyle.alert,
            actions: nil,
            from: nil
        )
    }
    
    func showFailedTransactionAlert() {
        dialogService.showAlert(
            title: nil,
            message: .adamantLocalized.sharedErrors.inconsistentTransaction,
            style: AdamantAlertStyle.alert,
            actions: nil,
            from: nil
        )
    }
}

extension ChatViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        updateMessages(performFetch: false)
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
    
    func setupObservers() {
        inputText
            .removeDuplicates()
            .sink { [weak self] _ in self?.inputTextUpdated() }
            .store(in: &subscriptions)
    }
    
    func loadMessages(address: String, offset: Int, loadingStatus: ChatLoadingStatus) {
        guard !isLoading else { return }
        
        _loadingStatus.value = loadingStatus
        chatsProvider.getChatMessages(
            with: address,
            offset: offset
        ) { [weak self] in
            DispatchQueue.onMainAsync {
                self?.updateMessages(performFetch: true)
                self?._loadingStatus.value = nil
            }
        }
    }
    
    func updateMessages(performFetch: Bool) {
        if performFetch {
            try? controller?.performFetch()
        }
        
        chatTransactions = controller?.fetchedObjects ?? []
    }
    
    func reset() {
        _sender.value = .default
        _messages.value = []
        _loadingStatus.value = nil
        inputText.value = ""
        _isSendingAvailable.value = false
        _messageIdToShow.value = nil
        controller = nil
        chatroom = nil
        preservationDelegate = nil
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
                inputText.value = sentText
            case .notEnoughMoneyToSend:
                inputText.value = sentText
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
    
    func inputTextUpdated() {
        guard !inputText.value.isEmpty else {
            _fee.value = ""
            return
        }
        
        let feeString = AdamantBalanceFormat.full.format(
            AdamantMessage.text(inputText.value).fee,
            withCurrencySymbol: AdmWalletService.currencySymbol
        )
        
        _fee.value = "~\(feeString)"
    }
}

private let dateHeaderTimeInterval: TimeInterval = 3600
