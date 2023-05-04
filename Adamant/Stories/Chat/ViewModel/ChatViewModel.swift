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
import UIKit

@MainActor
final class ChatViewModel: NSObject {
    // MARK: Dependencies
    
    private let chatsProvider: ChatsProvider
    private let markdownParser: MarkdownParser
    private let transfersProvider: TransfersProvider
    private let chatMessagesListFactory: ChatMessagesListFactory
    private let addressBookService: AddressBookService
    private let visibleWalletService: VisibleWalletsService
    private let accountService: AccountService
    private let accountProvider: AccountsProvider
    private let richTransactionStatusService: RichTransactionStatusService
    private let chatCacheService: ChatCacheService
    private let richMessageProviders: [String: RichMessageProvider]
    
    // MARK: Properties
    
    private var tasksStorage = TaskManager()
    private weak var preservationDelegate: ChatPreservationDelegate?
    private var controller: NSFetchedResultsController<ChatTransaction>?
    private var subscriptions = Set<AnyCancellable>()
    private var timerSubscription: AnyCancellable?
    private var messageIdToShow: String?
    private var isLoading = false
    private var animationIds: [String: String] = [:] {
        didSet {
            animationIds.forEach { (key, value) in
                guard let index = messages.firstIndex(where: { $0.messageId == key })
                else { return }
                messages[index].animationId = value
            }
        }
    }
    
    private var isNeedToLoadMoreMessages: Bool {
        get async {
            guard let address = chatroom?.partner?.address else { return false }
            
            return await chatsProvider.chatLoadedMessages[address] ?? .zero
                < chatsProvider.chatMaxMessages[address] ?? .zero
        }
    }
    
    private(set) var sender = ChatSender.default
    private(set) var chatroom: Chatroom?
    private(set) var chatTransactions: [ChatTransaction] = []
    
    var tempOffsets: [String] = []

    let didTapTransfer = ObservableSender<String>()
    let dialog = ObservableSender<ChatDialog>()
    let didTapAdmChat = ObservableSender<(Chatroom, String?)>()
    let didTapAdmSend = ObservableSender<AdamantAddress>()
    let closeScreen = ObservableSender<Void>()
    
    @ObservableValue private(set) var isHeaderLoading = false
    @ObservableValue private(set) var fullscreenLoading = false
    @ObservableValue private(set) var messages = [ChatMessage]()
    @ObservableValue private(set) var isAttachmentButtonAvailable = false
    @ObservableValue private(set) var isSendingAvailable = false
    @ObservableValue private(set) var fee = ""
    @ObservableValue private(set) var partnerName: String?
    @ObservableValue var swipeState: SwipeableView.State = .ended
    @ObservableValue var inputText = ""
    @ObservableValue var replyMessage: MessageModel?
    @ObservableValue var scrollToMessage: (String?, String?)
    
    var startPosition: ChatStartPosition? {
        if let messageIdToShow = messageIdToShow {
            return .messageId(messageIdToShow)
        }
        
        guard let address = chatroom?.partner?.address else { return nil }
        return chatsProvider.getChatPositon(for: address).map { .offset(.init($0)) }
    }
    
    var freeTokensURL: URL? {
        guard let address = accountService.account?.address else { return nil }
        let urlString: String = .adamantLocalized.wallets.getFreeTokensUrl(for: address)
        
        guard let url = URL(string: urlString) else {
            dialog.send(.error(
                "Failed to create URL with string: \(urlString)",
                supportEmail: true
            ))
            return nil
        }
        
        return url
    }
    
    init(
        chatsProvider: ChatsProvider,
        markdownParser: MarkdownParser,
        transfersProvider: TransfersProvider,
        chatMessagesListFactory: ChatMessagesListFactory,
        addressBookService: AddressBookService,
        visibleWalletService: VisibleWalletsService,
        accountService: AccountService,
        accountProvider: AccountsProvider,
        richTransactionStatusService: RichTransactionStatusService,
        chatCacheService: ChatCacheService,
        richMessageProviders: [String: RichMessageProvider]
    ) {
        self.chatsProvider = chatsProvider
        self.markdownParser = markdownParser
        self.transfersProvider = transfersProvider
        self.chatMessagesListFactory = chatMessagesListFactory
        self.addressBookService = addressBookService
        self.richMessageProviders = richMessageProviders
        self.visibleWalletService = visibleWalletService
        self.accountService = accountService
        self.accountProvider = accountProvider
        self.richTransactionStatusService = richTransactionStatusService
        self.chatCacheService = chatCacheService
        super.init()
        setupObservers()
    }
    
    func setup(
        account: AdamantAccount?,
        chatroom: Chatroom,
        messageToShow: MessageTransaction?,
        preservationDelegate: ChatPreservationDelegate?
    ) {
        assert(self.chatroom == nil, "Can't setup several times")
        self.chatroom = chatroom
        self.preservationDelegate = preservationDelegate
        controller = chatsProvider.getChatController(for: chatroom)
        controller?.delegate = self
        isSendingAvailable = !chatroom.isReadonly
        messageIdToShow = messageToShow?.chatMessageId
        updateTitle()
        updateAttachmentButtonAvailability()
        
        if let account = account {
            sender = .init(senderId: account.address, displayName: account.address)
        }
        
        if let partnerAddress = chatroom.partner?.address {
            preservationDelegate?.getPreservedMessageFor(
                address: partnerAddress,
                thenRemoveIt: true
            ).map { inputText = $0 }
            
            let cachedMessages = chatCacheService.getMessages(address: partnerAddress)
            messages = cachedMessages ?? []
            fullscreenLoading = cachedMessages == nil
        }
    }
    
    func loadFirstMessagesIfNeeded() {
        Task {
            guard let address = chatroom?.partner?.address else {
                fullscreenLoading = false
                return
            }
            
            let isChatLoaded = await chatsProvider.isChatLoaded(with: address)
            
            if address == AdamantContacts.adamantWelcomeWallet.name || isChatLoaded {
                updateTransactions(performFetch: true)
            } else {
                await loadMessages(address: address, offset: .zero)
            }
        }.stored(in: tasksStorage)
    }
    
    func loadMoreMessagesIfNeeded() {
        guard !isLoading else { return }
        
        Task {
            guard
                let address = chatroom?.partner?.address,
                await isNeedToLoadMoreMessages
            else { return }
            
            let offset = await chatsProvider.chatLoadedMessages[address] ?? .zero
            await loadMessages(address: address, offset: offset)
        }.stored(in: tasksStorage)
    }
    
    func sendMessage(text: String) {
        guard let partnerAddress = chatroom?.partner?.address else { return }
        
        guard chatroom?.partner?.isDummy != true else {
            dialog.send(.dummy(partnerAddress))
            return
        }
        
        Task {
            let message: AdamantMessage
            
            if let replyMessage = replyMessage {
                message = .richMessage(
                    payload: RichMessageReply(
                        replyto_id: replyMessage.id,
                        reply_message: text
                    )
                )
            } else {
                message = markdownParser.parse(text).length == text.count
                ? .text(text)
                : .markdownText(text)
            }
            
            guard await validateSendingMessage(message: message) else { return }
            
            replyMessage = nil
            
            do {
                _ = try await chatsProvider.sendMessage(
                    message,
                    recipientId: partnerAddress,
                    from: chatroom
                )
            } catch {
                await handleMessageSendingError(error: error, sentText: text)
            }
        }.stored(in: tasksStorage)
    }
    
    func forceUpdateTransactionStatus(id: String) {
        Task {
            guard
                let transaction = chatTransactions.first(where: { $0.chatMessageId == id }),
                let richMessageTransaction = transaction as? RichMessageTransaction
            else { return }
            
            await richTransactionStatusService.forceUpdate(transaction: richMessageTransaction)
        }.stored(in: tasksStorage)
    }
    
    func preserveMessage(_ message: String) {
        guard let partnerAddress = chatroom?.partner?.address else { return }
        preservationDelegate?.preserveMessage(message, forAddress: partnerAddress)
    }
    
    func blockChat() {
        Task {
            guard let address = chatroom?.partner?.address else {
                return assertionFailure("Can't block user without address")
            }
            
            chatroom?.isHidden = true
            try? chatroom?.managedObjectContext?.save()
            await chatsProvider.blockChat(with: address)
            closeScreen.send()
        }
    }
    
    func getKvsName(for address: String) -> String? {
        return addressBookService.getName(for: address)
    }
    
    func setNewName(_ newName: String) {
        guard let address = chatroom?.partner?.address else {
            return assertionFailure("Can't set name without address")
        }
        
        Task {
            await addressBookService.set(name: newName, for: address)
        }.stored(in: tasksStorage)
        
        partnerName = newName
    }
    
    func saveChatOffset(_ offset: CGFloat?) {
        guard let address = chatroom?.partner?.address else { return }
        chatsProvider.setChatPositon(for: address, position: offset.map { Double.init($0) })
    }
    
    func entireChatWasRead() {
        Task {
            guard
                let chatroom = chatroom,
                chatroom.hasUnreadMessages == true || chatroom.lastTransaction?.isUnread == true
            else { return }
            
            await chatsProvider.markChatAsRead(chatroom: chatroom)
        }
    }
    
    func hideMessage(id: String) {
        Task {
            guard let transaction = chatTransactions.first(where: { $0.chatMessageId == id })
            else { return }
            
            transaction.isHidden = true
            try? transaction.managedObjectContext?.save()
            
            await chatroom?.updateLastTransaction()
            await chatsProvider.removeMessage(with: transaction.transactionId)
        }
    }
    
    func didSelectURL(_ url: URL) {
        if url.scheme == "adm" {
            guard let adm = url.absoluteString.getLegacyAdamantAddress(),
                  let partnerAddress = chatroom?.partner?.address
            else {
                return
            }
            
            dialog.send(.admMenu(adm, partnerAddress: partnerAddress))
            return
        }
        
        dialog.send(.url(url))
    }
    
    func process(adm: AdamantAddress, action: AddressChatShareType) {
        Task {
            if action == .send {
                didTapAdmSend.send(adm)
                return
            }
            
            guard let room = await self.chatsProvider.getChatroom(for: adm.address) else {
                await self.findAccount(with: adm.address, name: adm.name, message: adm.message)
                return
            }
            
            self.startNewChat(with: room, name: adm.name, message: adm.message)
        }
    }
    
    func cancelMessage(id: String) {
        Task {
            guard let transaction = chatTransactions.first(where: { $0.chatMessageId == id })
            else { return }
            
            do {
                try await chatsProvider.cancelMessage(transaction)
            } catch {
                switch error as? ChatsProviderError {
                case .invalidTransactionStatus:
                    dialog.send(.warning(.adamantLocalized.chat.cancelError))
                default:
                    dialog.send(.richError(error))
                }
            }
        }.stored(in: tasksStorage)
    }
    
    func retrySendMessage(id: String) {
        Task {
            guard let transaction = chatTransactions.first(where: { $0.chatMessageId == id })
            else { return }
            
            do {
                try await chatsProvider.retrySendMessage(transaction)
            } catch {
                switch error as? ChatsProviderError {
                case .invalidTransactionStatus:
                    break
                default:
                    dialog.send(.richError(error))
                }
            }
        }.stored(in: tasksStorage)
    }
    
    func scroll(to message: ChatMessageReplyCell.Model) {
        guard let partnerAddress = chatroom?.partner?.address else { return }
        Task {
            do {
                if !chatTransactions.contains(
                    where: { $0.transactionId == message.replyId }
                ) {
                    dialog.send(.progress(true))
                    try await chatsProvider.loadTransactionsUntilFind(
                        message.replyId,
                        recipient: partnerAddress
                    )
                }
                
                scrollToMessage = (message.replyId, message.id)
                animationIds[message.replyId] = UUID().uuidString
                
                dialog.send(.progress(false))
            } catch {
                print(error)
                dialog.send(.progress(false))
                dialog.send(.richError(error))
            }
        }.stored(in: tasksStorage)
    }
}

extension ChatViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        updateTransactions(performFetch: false)
    }
}

private extension ChatViewModel {
    func setupObservers() {
        $inputText
            .removeDuplicates()
            .sink { [weak self] _ in self?.inputTextUpdated() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantVisibleWalletsService.visibleWallets)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateAttachmentButtonAvailability() }
            .store(in: &subscriptions)
        
        Task {
            await chatsProvider.stateObserver
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.isHeaderLoading = state == .updating ? true : false
                }
                .store(in: &subscriptions)
        }.stored(in: tasksStorage)
    }
    
    func loadMessages(address: String, offset: Int) async {
        guard !isLoading else { return }
        isLoading = true
        
        await chatsProvider.getChatMessages(
            with: address,
            offset: offset
        )
        
        updateTransactions(performFetch: true)
    }
    
    func updateTransactions(performFetch: Bool) {
        if performFetch {
            try? controller?.performFetch()
        }
        
        chatTransactions = controller?.fetchedObjects ?? []
        updateMessages(resetLoadingProperty: performFetch)
    }
    
    func updateMessages(resetLoadingProperty: Bool) {
        timerSubscription = nil
        
        Task(priority: .userInitiated) { [chatTransactions, sender] in
            var expirationTimestamp: TimeInterval?

            let messages = await chatMessagesListFactory.makeMessages(
                transactions: chatTransactions,
                sender: sender,
                isNeedToLoadMoreMessages: isNeedToLoadMoreMessages,
                expirationTimestamp: &expirationTimestamp,
                animationIds: animationIds
            )
            
            await setupNewMessages(
                newMessages: messages,
                resetLoadingProperty: resetLoadingProperty,
                expirationTimestamp: expirationTimestamp
            )
        }
    }
    
    func setupNewMessages(
        newMessages: [ChatMessage],
        resetLoadingProperty: Bool,
        expirationTimestamp: TimeInterval?
    ) async {
        messages = newMessages
        
        if let address = chatroom?.partner?.address {
            chatCacheService.setMessages(address: address, messages: newMessages)
        }
        
        if resetLoadingProperty {
            isLoading = false
            fullscreenLoading = false
        }
        
        guard let expirationTimestamp = expirationTimestamp else { return }
        setupMessagesUpdateTimer(expirationTimestamp: expirationTimestamp)
    }
    
    func setupMessagesUpdateTimer(expirationTimestamp: TimeInterval) {
        let currentTimestamp = Date().timeIntervalSince1970
        guard currentTimestamp < expirationTimestamp else { return }
        let interval = expirationTimestamp - currentTimestamp
        
        timerSubscription = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.updateMessages(resetLoadingProperty: false) }
    }
    
    func validateSendingMessage(message: AdamantMessage) async -> Bool {
        let validationStatus = await chatsProvider.validateMessage(message)
        
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
    
    func handleMessageSendingError(error: Error, sentText: String) async {
        switch error as? ChatsProviderError {
        case .messageNotValid:
            inputText = sentText
        case .notEnoughMoneyToSend:
            inputText = sentText
            guard await transfersProvider.hasTransactions else {
                dialog.send(.freeTokenAlert)
                return
            }
        case .accountNotFound, .accountNotInitiated, .dependencyError, .internalError, .networkError, .notLogged, .requestCancelled, .serverError, .transactionNotFound, .invalidTransactionStatus, .none:
            break
        }
        
        dialog.send(.richError(error))
    }
    
    func inputTextUpdated() {
        guard !inputText.isEmpty else {
            fee = ""
            return
        }
        
        let feeString = AdamantBalanceFormat.full.format(
            AdamantMessage.text(inputText).fee,
            withCurrencySymbol: AdmWalletService.currencySymbol
        )
        
        fee = "~\(feeString)"
    }
    
    func updateTitle() {
        partnerName = chatroom?.getName(addressBookService: addressBookService)
    }
    
    func updateAttachmentButtonAvailability() {
        let isAnyWalletVisible = accountService.wallets
            .map { visibleWalletService.isInvisible($0) }
            .contains(false)
        
        isAttachmentButtonAvailable = isAnyWalletVisible
    }
    
    func findAccount(with address: String, name: String?, message: String?) async {
        dialog.send(.progress(true))
        do {
            let account = try await accountProvider.getAccount(byAddress: address)
            
            self.dialog.send(.progress(false))
            guard let chatroom = account.chatroom else { return }
            self.setNameIfNeeded(for: account, chatroom: account.chatroom, name: name)
            account.chatroom?.isForcedVisible = true
            self.startNewChat(with: chatroom, message: message)
        } catch let error as AccountsProviderError {
            switch error {
            case .dummy, .notFound, .notInitiated:
                self.dialog.send(.progress(false))
                self.dialog.send(.dummy(address))
            case .invalidAddress, .networkError:
                self.dialog.send(.progress(false))
                self.dialog.send(.alert(error.localized))
            case .serverError(let apiError):
                self.dialog.send(.progress(false))
                if let apiError = apiError as? ApiServiceError,
                   case .internalError(let message, _) = apiError,
                   message == String.adamantLocalized.sharedErrors.unknownError {
                    self.dialog.send(.alert(AccountsProviderError.notFound(address: address).localized))
                    return
                }
                
                self.dialog.send(.error(error.localized, supportEmail: false))
            }
        } catch {
            self.dialog.send(.error(
                error.localizedDescription,
                supportEmail: false
            ))
        }
    }
    
    func setNameIfNeeded(for account: CoreDataAccount?, chatroom: Chatroom?, name: String?) {
        guard let name = name,
              let account = account,
              let address = account.address,
              account.name == nil,
              addressBookService.getName(for: address) == nil
        else {
            return
        }
        
        Task {
            await addressBookService.set(name: name, for: address)
        }.stored(in: tasksStorage)
        
        account.name = name
        if let chatroom = chatroom, chatroom.title == nil {
            chatroom.title = name
        }
    }
    
    func startNewChat(with chatroom: Chatroom, name: String? = nil, message: String? = nil) {
        setNameIfNeeded(for: chatroom.partner, chatroom: chatroom, name: name)
        didTapAdmChat.send((chatroom, message))
    }
}
