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
    private let visibleWalletService: VisibleWalletsService
    private let accountService: AccountService
    private let accountProvider: AccountsProvider
    private let richMessageProviders: [String: RichMessageProvider]
    private lazy var chatMessagesListFactory = makeChatMessagesListFactory()
    
    // MARK: Properties
    
    private weak var preservationDelegate: ChatPreservationDelegate?
    private var controller: NSFetchedResultsController<ChatTransaction>?
    private var subscriptions = Set<AnyCancellable>()
    private var timerSubscription: AnyCancellable?
    private var messageIdToShow: String?
    private var isLoading = false
    
    private(set) var chatroom: Chatroom?
    private(set) var chatTransactions: [ChatTransaction] = []
    
    let didTapTransfer = ObservableSender<String>()
    let dialog = ObservableSender<ChatDialog>()
    let didTapAdmChat = ObservableSender<(Chatroom, String?)>()
    let didTapAdmSend = ObservableSender<AdamantAddress>()
    
    private let _closeScreen = ObservableSender<Void>()
    var closeScreen: some Observable<Void> { _closeScreen }
    
    @ObservableValue private(set) var fullscreenLoading = false
    @ObservableValue private(set) var sender = ChatSender.default
    @ObservableValue private(set) var messages = [ChatMessage]()
    @ObservableValue private(set) var isAttachmentButtonAvailable = false
    @ObservableValue private(set) var isSendingAvailable = false
    @ObservableValue private(set) var fee = ""
    @ObservableValue private(set) var partnerName: String?
    @ObservableValue var inputText = ""
    
    var startPosition: ChatStartPosition? {
        get async {
            if let messageIdToShow = messageIdToShow {
                return .messageId(messageIdToShow)
            }
            
            guard let address = chatroom?.partner?.address else { return nil }
            return await chatsProvider.getChatPositon(for: address).map { .offset(.init($0)) }
        }
    }
    
    var freeTokensURL: URL? {
        guard let address = chatroom?.partner?.address else { return nil }
        let urlString: String = .adamantLocalized.wallets.getFreeTokensUrl(for: address)
        
        guard let url = URL(string: urlString) else {
            dialog.send(.error("Failed to create URL with string: \(urlString)"))
            return nil
        }
        
        return url
    }
    
    var isNeedToLoadMoreMessages: Bool = false
    
    private var firstLoadTask: Task<(), Never>?
    private var mooreLoadTask: Task<(), Never>?
    private var transactionStatusTask: Task<(), Never>?
    private var cancelMessageTask: Task<(), Never>?
    private var retrySendMessageTask: Task<(), Never>?
    private var sendMessageTask: Task<(), Never>?
    
    init(
        chatsProvider: ChatsProvider,
        markdownParser: MarkdownParser,
        transfersProvider: TransfersProvider,
        chatMessageFactory: ChatMessageFactory,
        addressBookService: AddressBookService,
        visibleWalletService: VisibleWalletsService,
        accountService: AccountService,
        accountProvider: AccountsProvider,
        richMessageProviders: [String: RichMessageProvider]
    ) {
        self.chatsProvider = chatsProvider
        self.markdownParser = markdownParser
        self.transfersProvider = transfersProvider
        self.chatMessageFactory = chatMessageFactory
        self.addressBookService = addressBookService
        self.richMessageProviders = richMessageProviders
        self.visibleWalletService = visibleWalletService
        self.accountService = accountService
        self.accountProvider = accountProvider
        super.init()
        setupObservers()
    }
    
    deinit {
        firstLoadTask?.cancel()
        mooreLoadTask?.cancel()
        transactionStatusTask?.cancel()
        cancelMessageTask?.cancel()
        retrySendMessageTask?.cancel()
        sendMessageTask?.cancel()
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
        }
    }
    
    func loadFirstMessagesIfNeeded() {
        firstLoadTask = Task {
            guard let address = chatroom?.partner?.address else { return }
            
            let isChatLoading = await chatsProvider.isChatLoaded(with: address)
            
            if address == AdamantContacts.adamantWelcomeWallet.name || isChatLoading {
                await updateTransactions(performFetch: true)
            } else {
                await loadMessages(address: address, offset: .zero, fullscreenLoading: true)
            }
        }
    }
    
    func loadMoreMessagesIfNeeded() {
        mooreLoadTask = Task {
            guard
                let address = chatroom?.partner?.address,
                isNeedToLoadMoreMessages
            else { return }
            
            let offset = await chatsProvider.chatLoadedMessages[address] ?? .zero
            await loadMessages(address: address, offset: offset, fullscreenLoading: false)
        }
    }
    
    func sendMessage(text: String) {
        sendMessageTask = Task {
            let message: AdamantMessage = markdownParser.parse(text).length == text.count
            ? .text(text)
            : .markdownText(text)
            
            guard
                let partnerAddress = chatroom?.partner?.address,
                await validateSendingMessage(message: message)
            else { return }
            
            do {
                _ = try await chatsProvider.sendMessage(
                    message,
                    recipientId: partnerAddress,
                    from: chatroom
                )
            } catch {
                await handleMessageSendingError(error: error, sentText: text)
            }
        }
    }
    
    func loadTransactionStatusIfNeeded(id: String, forceUpdate: Bool) {
        transactionStatusTask = Task {
            guard
                let transaction = chatTransactions.first(where: { $0.chatMessageId == id }),
                let richMessageTransaction = transaction as? RichMessageTransaction,
                richMessageTransaction.transactionStatus?.isFinal != true || forceUpdate
            else { return }
            
        if forceUpdate,
           let index = messages.firstIndex(where: { id == $0.id }),
           case var .transaction(model) = messages[index].content {
            model.status = .notInitiated
            messages[index].content = .transaction(model)
        }

            await chatsProvider.updateStatus(for: richMessageTransaction, resetBeforeUpdate: forceUpdate)
        }
    }
    
    func preserveMessage(_ message: String) {
        guard let partnerAddress = chatroom?.partner?.address else { return }
        preservationDelegate?.preserveMessage(message, forAddress: partnerAddress)
    }
    
    @MainActor
    func blockChat() {
        Task {
            guard let address = chatroom?.partner?.address else {
                return assertionFailure("Can't block user without address")
            }
            
            chatroom?.isHidden = true
            try? chatroom?.managedObjectContext?.save()
            await chatsProvider.blockChat(with: address)
            _closeScreen.send()
        }
    }
    
    func setNewName(_ newName: String) {
        guard let address = chatroom?.partner?.address else {
            return assertionFailure("Can't set name without address")
        }
        
        addressBookService.set(name: newName, for: address)
        updateTitle()
    }
    
    func saveChatOffset(_ offset: CGFloat?) {
        Task {
            guard let address = chatroom?.partner?.address else { return }
            await chatsProvider.setChatPositon(for: address, position: offset.map { Double.init($0) })
        }
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
            guard let id = transaction.transactionId else { return }
            await chatsProvider.removeMessage(with: id)
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
        cancelMessageTask = Task {
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
        }
    }
    
    func retrySendMessage(id: String) {
        retrySendMessageTask = Task {
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
        }
    }
}

extension ChatViewModel: NSFetchedResultsControllerDelegate {
    @MainActor
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
    }
    
    @MainActor
    func loadMessages(address: String, offset: Int, fullscreenLoading: Bool) async {
        guard !isLoading else { return }

        isLoading = true
        self.fullscreenLoading = fullscreenLoading
        
        await chatsProvider.getChatMessages(
            with: address,
            offset: offset
        )
        
        updateTransactions(performFetch: true)
    }
    
    @MainActor
    func updateTransactions(performFetch: Bool) {
        if performFetch {
            try? controller?.performFetch()
        }
        
        chatTransactions = controller?.fetchedObjects ?? []
        updateMessages(resetLoadingProperty: true)
    }
    
    func updateMessages(resetLoadingProperty: Bool) {
        timerSubscription = nil
        
        Task(priority: .userInitiated) { [chatTransactions, sender, isNeedToLoadMoreMessages] in
            var expirationTimestamp: TimeInterval?
            checkIfNeedToLoadMooreMessages()

            let messages = await chatMessagesListFactory.makeMessages(
                transactions: chatTransactions,
                sender: sender,
                isNeedToLoadMoreMessages: isNeedToLoadMoreMessages,
                expirationTimestamp: &expirationTimestamp
            )
            
            await setupNewMessages(
                newMessages: messages,
                resetLoadingProperty: resetLoadingProperty,
                expirationTimestamp: expirationTimestamp
            )
        }
    }
    
    @MainActor func setupNewMessages(
        newMessages: [ChatMessage],
        resetLoadingProperty: Bool,
        expirationTimestamp: TimeInterval?
    ) async {
        messages = newMessages
        fullscreenLoading = false
        
        if resetLoadingProperty {
            isLoading = false
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
    
    func checkIfNeedToLoadMooreMessages() {
        Task {
            guard let address = chatroom?.partner?.address else {
                isNeedToLoadMoreMessages = false
                return
            }
            isNeedToLoadMoreMessages = await chatsProvider.chatLoadedMessages[address] ?? .zero < chatsProvider.chatMaxMessages[address] ?? .zero
        }
    }
    
    func reset() {
        sender = .default
        chatTransactions = []
        messages = []
        fullscreenLoading = false
        isLoading = false
        inputText = ""
        isAttachmentButtonAvailable = false
        isSendingAvailable = false
        fee = ""
        partnerName = nil
        messageIdToShow = nil
        controller = nil
        chatroom = nil
        preservationDelegate = nil
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
    
    @MainActor
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
    
    @MainActor
    func findAccount(with address: String, name: String?, message: String?) async {
        dialog.send(.progress(true))
        do {
            let account = try await accountProvider.getAccount(byAddress: address)
            
            self.dialog.send(.progress(false))
            guard let chatroom = account.chatroom else { return }
            self.setNameIfNeeded(for: account, chatroom: account.chatroom, name: name)
            account.chatroom?.isForcedVisible = true
            self.startNewChat(with: chatroom, message: message)
        } catch let error as AccountsProviderResult {
            switch error {
            case .success(let account):
                self.dialog.send(.progress(false))
                guard let chatroom = account.chatroom else { return }
                self.setNameIfNeeded(for: account, chatroom: account.chatroom, name: name)
                account.chatroom?.isForcedVisible = true
                self.startNewChat(with: chatroom, message: message)
            case .dummy:
                self.dialog.send(.progress(false))
                self.dialog.send(.dummy(address))
            case .notFound, .invalidAddress, .notInitiated, .networkError:
                self.dialog.send(.progress(false))
                self.dialog.send(.alert(error.localized))
            case .serverError(let apiError):
                self.dialog.send(.progress(false))
                if let apiError = apiError as? ApiServiceError,
                   case .internalError(let message, _) = apiError,
                   message == String.adamantLocalized.sharedErrors.unknownError {
                    self.dialog.send(.alert(AccountsProviderResult.notFound(address: address).localized))
                    return
                }
                
                self.dialog.send(.error(error.localized))
            }
        } catch {
            self.dialog.send(.error(error.localizedDescription))
        }
    }
    
    func setNameIfNeeded(for account: CoreDataAccount?, chatroom: Chatroom?, name: String?) {
        guard let name = name,
              let account = account,
              account.name == nil
        else {
            return
        }
        account.name = name
        if let chatroom = chatroom, chatroom.title == nil {
            chatroom.title = name
        }
    }
    
    func startNewChat(with chatroom: Chatroom, name: String? = nil, message: String? = nil) {
        setNameIfNeeded(for: chatroom.partner, chatroom: chatroom, name: name)
        didTapAdmChat.send((chatroom, message))
    }
    
    func makeChatMessagesListFactory() -> ChatMessagesListFactory {
        .init(
            chatMessageFactory: chatMessageFactory,
            didTapTransfer: { [didTapTransfer] in didTapTransfer.send($0) },
            forceUpdateStatusAction: { [weak self] in
                self?.loadTransactionStatusIfNeeded(id: $0, forceUpdate: true)
            }
        )
    }
}