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
    private let transfersProvider: TransfersProvider
    private let chatMessageFactory: ChatMessageFactory
    private let addressBookService: AddressBookService
    private let richMessageProviders: [String: RichMessageProvider]
    
    // MARK: Properties
    
    private let _sender = ObservableProperty(ChatSender.default)
    private let _messages = ObservableProperty([ChatMessage]())
    private let _loadingStatus = ObservableProperty<ChatLoadingStatus?>(nil)
    private let _isSendingAvailable = ObservableProperty(false)
    private let _messageIdToShow = ObservableProperty<String?>(nil)
    private let _fee = ObservableProperty("")
    private let _partnerName = ObservableProperty<String?>(nil)
    private let _closeScreen = ObservableSender<Void>()
    
    private weak var preservationDelegate: ChatPreservationDelegate?
    private var controller: NSFetchedResultsController<ChatTransaction>?
    private var subscriptions = Set<AnyCancellable>()
    private var timerSubscription: AnyCancellable?
    
    private(set) var chatroom: Chatroom?
    private(set) var chatTransactions: [ChatTransaction] = []
    
    let inputText = ObservableProperty("")
    let didTapTransfer = ObservableSender<String>()
    let dialog = ObservableSender<ChatDialog>()
    
    var sender: ObservableVariable<ChatSender> { _sender.eraseToGetter() }
    var messages: ObservableVariable<[ChatMessage]> { _messages.eraseToGetter() }
    var loadingStatus: ObservableVariable<ChatLoadingStatus?> { _loadingStatus.eraseToGetter() }
    var isSendingAvailable: ObservableVariable<Bool> { _isSendingAvailable.eraseToGetter() }
    var messageIdToShow: Observable<String?> { _messageIdToShow.eraseToAnyPublisher() }
    var fee: ObservableVariable<String> { _fee.eraseToGetter() }
    var partnerName: ObservableVariable<String?> { _partnerName.eraseToGetter() }
    var closeScreen: Observable<Void> { _closeScreen.eraseToAnyPublisher() }
    
    var freeTokensURL: URL? {
        guard let address = chatroom?.partner?.address else { return nil }
        let urlString: String = .adamantLocalized.wallets.getFreeTokensUrl(for: address)
        
        guard let url = URL(string: urlString) else {
            dialog.send(.error("Failed to create URL with string: \(urlString)"))
            return nil
        }
        
        return url
    }
    
    init(
        chatsProvider: ChatsProvider,
        markdownParser: MarkdownParser,
        transfersProvider: TransfersProvider,
        chatMessageFactory: ChatMessageFactory,
        addressBookService: AddressBookService,
        richMessageProviders: [String: RichMessageProvider]
    ) {
        self.chatsProvider = chatsProvider
        self.markdownParser = markdownParser
        self.transfersProvider = transfersProvider
        self.chatMessageFactory = chatMessageFactory
        self.addressBookService = addressBookService
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
        updateTitle()
        
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
            updateTransactions(performFetch: true)
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
    
    func blockChat() {
        guard let address = chatroom?.partner?.address else {
            return assertionFailure("Can't block user without address")
        }
        
        chatroom?.isHidden = true
        try? chatroom?.managedObjectContext?.save()
        chatsProvider.blockChat(with: address)
        _closeScreen.send()
    }
    
    func setNewName(_ newName: String) {
        guard let address = chatroom?.partner?.address else {
            return assertionFailure("Can't set name without address")
        }
        
        addressBookService.set(name: newName, for: address)
        updateTitle()
    }
}

extension ChatViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        updateTransactions(performFetch: false)
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
                self?.updateTransactions(performFetch: true)
                self?._loadingStatus.value = nil
            }
        }
    }
    
    func updateTransactions(performFetch: Bool) {
        if performFetch {
            try? controller?.performFetch()
        }
        
        chatTransactions = controller?.fetchedObjects ?? []
        updateMessages()
    }
    
    func updateMessages() {
        timerSubscription = nil
        var minTimestamp: TimeInterval?
        var expireDate: Date?
        
        _messages.value = chatTransactions.map {
            let message = chatMessageFactory.makeMessage($0, expireDate: &expireDate)
            let timestamp = expireDate?.timeIntervalSince1970
            
            if let timestamp = timestamp, timestamp < minTimestamp ?? .greatestFiniteMagnitude {
                minTimestamp = timestamp
            }
            
            expireDate = nil
            return message
        }
        
        let currentTimestamp = Date().timeIntervalSince1970
        if let minTimestamp = minTimestamp, currentTimestamp < minTimestamp {
            setupMessagesUpdateTimer(interval: minTimestamp - currentTimestamp)
        }
    }
    
    func reset() {
        _sender.value = .default
        _messages.value = []
        _loadingStatus.value = nil
        inputText.value = ""
        _isSendingAvailable.value = false
        _messageIdToShow.value = nil
        _fee.value = ""
        _partnerName.value = nil
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
            dialog.send(.toast(validationStatus.localized))
            return false
        }
    }
    
    func handleMessageSendingResult(result: ChatsProviderResultWithTransaction, sentText: String) {
        switch result {
        case .success:
            break
        case let .failure(error):
            switch error {
            case .messageNotValid:
                inputText.value = sentText
            case .notEnoughMoneyToSend:
                inputText.value = sentText
                guard transfersProvider.hasTransactions else {
                    dialog.send(.freeTokenAlert)
                    return
                }
            case .accountNotFound, .accountNotInitiated, .dependencyError, .internalError, .networkError, .notLogged, .requestCancelled, .serverError, .transactionNotFound:
                break
            }
            
            dialog.send(.richError(error))
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
    
    func updateTitle() {
        guard let partner = chatroom?.partner else { return }
        
        if let address = partner.address, let name = addressBookService.addressBook[address] {
            _partnerName.value = name.checkAndReplaceSystemWallets()
        } else if let name = partner.name {
            _partnerName.value = name
        } else {
            _partnerName.value = partner.address
        }
    }
    
    func setupMessagesUpdateTimer(interval: TimeInterval) {
        timerSubscription = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.updateMessages() }
    }
}

private let dateHeaderTimeInterval: TimeInterval = 3600
