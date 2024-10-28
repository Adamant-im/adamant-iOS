//
//  ChatViewModel.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

@preconcurrency import Combine
import CoreData
import MarkdownKit
import UIKit
import CommonKit
import AdvancedContextMenuKit
@preconcurrency import ElegantEmojiPicker
import FilesPickerKit
import FilesStorageKit

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
    private let richTransactionStatusService: TransactionsStatusServiceComposeProtocol
    private let chatCacheService: ChatCacheService
    private let walletServiceCompose: WalletServiceCompose
    private let avatarService: AvatarService
    private let emojiService: EmojiService
    private let chatPreservation: ChatPreservationProtocol
    private let filesStorage: FilesStorageProtocol
    private let chatFileService: ChatFileProtocol
    private let filesStorageProprieties: FilesStorageProprietiesProtocol
    private let apiServiceCompose: ApiServiceComposeProtocol
    private let reachabilityMonitor: ReachabilityMonitor
    private let filesPicker: FilesPickerProtocol
    
    let chatMessagesListViewModel: ChatMessagesListViewModel

    // MARK: Properties
    
    private var tasksStorage = TaskManager()
    private var controller: NSFetchedResultsController<ChatTransaction>?
    private var subscriptions = Set<AnyCancellable>()
    private var timerSubscription: AnyCancellable?
    private var messageIdToShow: String?
    private var isLoading = false
    
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
    private var tempCancellables = Set<AnyCancellable>()
    private var hideHeaderTimer: AnyCancellable?
    private let minDiffCountForOffset = 5
    private let minDiffCountForAnimateScroll = 20
    private let partnerImageSize: CGFloat = 25
    private let maxMessageLenght: Int = 10000
    private var previousArg: ChatContextMenuArguments?
    private var lastDateHeaderUpdate: Date = Date()
    private var havePartnerName: Bool = false
    private let delayHideHeaderInSeconds: Double = 2.0
    
    let minIndexForStartLoadNewMessages = 4
    let minOffsetForStartLoadNewMessages: CGFloat = 100
    var tempOffsets: [String] = []
    var needToAnimateCellIndex: Int?

    let didTapPartnerQR = ObservableSender<CoreDataAccount>()
    let didTapTransfer = ObservableSender<String>()
    let dialog = ObservableSender<ChatDialog>()
    let didTapAdmChat = ObservableSender<(Chatroom, String?)>()
    let didTapAdmSend = ObservableSender<AdamantAddress>()
    let closeScreen = ObservableSender<Void>()
    let updateChatRead = ObservableSender<Void>()
    let commitVibro = ObservableSender<Void>()
    let layoutIfNeeded = ObservableSender<Void>()
    let presentKeyboard = ObservableSender<Void>()
    let didTapSelectText = ObservableSender<String>()
    let presentFilePicker = ObservableSender<ShareType>()
    let presentSendTokensVC = ObservableSender<Void>()
    let presentMediaPickerVC = ObservableSender<Void>()
    let presentDocumentPickerVC = ObservableSender<Void>()
    let presentDocumentViewerVC = ObservableSender<([FileResult], Int)>()
    let presentDropView = ObservableSender<Bool>()
    
    @ObservableValue private(set) var isHeaderLoading = false
    @ObservableValue private(set) var fullscreenLoading = false
    @ObservableValue private(set) var messages = [ChatMessage]()
    @ObservableValue private(set) var isAttachmentButtonAvailable = false
    @ObservableValue private(set) var isSendingAvailable = false
    @ObservableValue private(set) var fee = ""
    @ObservableValue private(set) var partnerName: String?
    @ObservableValue private(set) var partnerImage: UIImage?
    @ObservableValue private(set) var isNeedToAnimateScroll = false
    @ObservableValue private(set) var dateHeader: String?
    @ObservableValue private(set) var dateHeaderHidden: Bool = true
    @ObservableValue var swipeState: SwipeableView.State = .ended
    @ObservableValue var inputText = ""
    @ObservableValue var replyMessage: MessageModel?
    @ObservableValue var scrollToMessage: (toId: String?, fromId: String?)
    @ObservableValue var filesPicked: [FileResult]?
    
    var startPosition: ChatStartPosition? {
        if let messageIdToShow = messageIdToShow {
            return .messageId(messageIdToShow, toBottomIfNotFound: true)
        }
        
        guard let address = chatroom?.partner?.address else { return nil }
        return chatsProvider.getChatPositon(for: address).map { .offset(.init($0)) }
    }
    
    var freeTokensURL: URL? {
        guard let address = accountService.account?.address else { return nil }
        let urlString: String = .adamant.wallets.getFreeTokensUrl(for: address)
        
        guard let url = URL(string: urlString) else {
            dialog.send(.error(
                "Failed to create URL with string: \(urlString)",
                supportEmail: true
            ))
            return nil
        }
        
        return url
    }
    
    private var hiddenMessageID: String? {
        didSet { updateHiddenMessage(&messages) }
    }
    
    lazy private(set) var mediaPickerDelegate = MediaPickerService(helper: filesPicker)
    lazy private(set) var documentPickerDelegate = DocumentPickerService(helper: filesPicker)
    lazy private(set) var documentViewerService = DocumentInteractionService()
    lazy private(set) var dropInteractionService = DropInteractionService(helper: filesPicker)
    
    init(
        chatsProvider: ChatsProvider,
        markdownParser: MarkdownParser,
        transfersProvider: TransfersProvider,
        chatMessagesListFactory: ChatMessagesListFactory,
        addressBookService: AddressBookService,
        visibleWalletService: VisibleWalletsService,
        accountService: AccountService,
        accountProvider: AccountsProvider,
        richTransactionStatusService: TransactionsStatusServiceComposeProtocol,
        chatCacheService: ChatCacheService,
        walletServiceCompose: WalletServiceCompose,
        avatarService: AvatarService,
        chatMessagesListViewModel: ChatMessagesListViewModel,
        emojiService: EmojiService,
        chatPreservation: ChatPreservationProtocol,
        filesStorage: FilesStorageProtocol,
        chatFileService: ChatFileProtocol,
        filesStorageProprieties: FilesStorageProprietiesProtocol,
        apiServiceCompose: ApiServiceComposeProtocol,
        reachabilityMonitor: ReachabilityMonitor,
        filesPicker: FilesPickerProtocol
    ) {
        self.chatsProvider = chatsProvider
        self.markdownParser = markdownParser
        self.transfersProvider = transfersProvider
        self.chatMessagesListFactory = chatMessagesListFactory
        self.addressBookService = addressBookService
        self.walletServiceCompose = walletServiceCompose
        self.visibleWalletService = visibleWalletService
        self.accountService = accountService
        self.accountProvider = accountProvider
        self.richTransactionStatusService = richTransactionStatusService
        self.chatCacheService = chatCacheService
        self.avatarService = avatarService
        self.chatMessagesListViewModel = chatMessagesListViewModel
        self.emojiService = emojiService
        self.chatPreservation = chatPreservation
        self.filesStorage = filesStorage
        self.chatFileService = chatFileService
        self.filesStorageProprieties = filesStorageProprieties
        self.apiServiceCompose = apiServiceCompose
        self.reachabilityMonitor = reachabilityMonitor
        self.filesPicker = filesPicker
        
        super.init()
        setupObservers()
    }
    
    func setup(
        account: AdamantAccount?,
        chatroom: Chatroom,
        messageIdToShow: String?
    ) {
        assert(self.chatroom == nil, "Can't setup several times")
        self.chatroom = chatroom
        self.messageIdToShow = messageIdToShow
        controller = chatsProvider.getChatController(for: chatroom)
        controller?.delegate = self
        isSendingAvailable = !chatroom.isReadonly
        updatePartnerInformation()
        updateAttachmentButtonAvailability()
        
        if let account = account {
            sender = .init(senderId: account.address, displayName: account.address)
        }
        
        if let partnerAddress = chatroom.partner?.address {
            chatPreservation.getPreservedMessageFor(
                address: partnerAddress,
                thenRemoveIt: true
            ).map { inputText = $0 }
            
            let cachedMessages = chatCacheService.getMessages(address: partnerAddress)
            messages = cachedMessages ?? []
            fullscreenLoading = cachedMessages == nil
            
            replyMessage = chatPreservation.getReplyMessage(address: partnerAddress, thenRemoveIt: true)
            
            filesPicked = chatPreservation.getPreservedFiles(
                for: partnerAddress,
                thenRemoveIt: true
            )
        }
    }
    
    func presentKeyboardOnStartIfNeeded() {
        guard !inputText.isEmpty
                || replyMessage != nil
                || (filesPicked?.count ?? .zero) > .zero
        else { return }
        
        presentKeyboard.send()
    }
    
    func loadFirstMessagesIfNeeded() {
        Task {
            guard let address = chatroom?.partner?.address else {
                fullscreenLoading = false
                return
            }
            
            let isChatLoaded = await chatsProvider.isChatLoaded(with: address)
            let isChatLoading = await chatsProvider.isChatLoading(with: address)
            
            guard !isChatLoading else {
                await waitForChatLoading(with: address)
                updateTransactions(performFetch: true)
                return
            }
            
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
        
        guard reachabilityMonitor.connection else {
            dialog.send(.alert(.adamant.sharedErrors.networkError))
            return
        }
        
        Task {
            guard apiServiceCompose.get(.adm)?.hasEnabledNode == true else {
                dialog.send(.alert(ApiServiceError.noEndpointsAvailable(
                    nodeGroupName: NodeGroup.adm.name
                ).localizedDescription))
                return
            }
            
            if !(filesPicked?.isEmpty ?? true) {
                do {
                    try await sendFiles(with: text)
                } catch {
                    await handleMessageSendingError(
                        error: error,
                        sentText: text,
                        filesPicked: filesPicked
                    )
                }
                return
            }
    
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
        chatPreservation.preserveMessage(message, forAddress: partnerAddress)
    }
    
    func preserveFiles() {
        guard let partnerAddress = chatroom?.partner?.address else { return }
        chatPreservation.preserveFiles(filesPicked, forAddress: partnerAddress)
    }
    
    func preserveReplayMessage() {
        guard let partnerAddress = chatroom?.partner?.address else { return }
        chatPreservation.setReplyMessage(replyMessage, forAddress: partnerAddress)
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
        havePartnerName = !newName.isEmpty
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
            
            chatroom?.updateLastTransaction()
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
                    dialog.send(.warning(.adamant.chat.cancelError))
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
            
            let message = messages.first(where: { $0.messageId == id })
            
            if case let .file(model) = message?.content {
                try? await chatFileService.resendMessage(
                    with: id,
                    text: model.value.content.comment.string,
                    chatroom: chatroom,
                    replyMessage: nil,
                    saveEncrypted: filesStorageProprieties.saveFileEncrypted()
                )
                return
            }
            
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
                guard await !chatsProvider.isMessageDeleted(id: message.replyId) else {
                    dialog.send(.alert(.adamant.chat.messageWasDeleted))
                    return
                }
                
                if !chatTransactions.contains(
                    where: { $0.transactionId == message.replyId }
                ) {
                    dialog.send(.progress(true))
                    try await chatsProvider.loadTransactionsUntilFound(
                        message.replyId,
                        recipient: partnerAddress
                    )
                }
                
                await waitForMessage(withId: message.replyId)
                
                scrollToMessage = (toId: message.replyId, fromId: message.id)
                
                dialog.send(.progress(false))
            } catch {
                print(error)
                dialog.send(.progress(false))
                dialog.send(.richError(error))
            }
        }.stored(in: tasksStorage)
    }
        
    func waitForMessage(withId messageId: String) async {
        guard !messages.contains(where: { $0.messageId == messageId }) else {
            return
        }
        
        await withUnsafeContinuation { continuation in
            $messages
                .filter { $0.contains(where: { $0.messageId == messageId }) }
                .sink { [weak self] _ in
                    self?.tempCancellables.removeAll()
                    continuation.resume()
                }.store(in: &tempCancellables)
        }
    }
    
    func replyMessageIfNeeded(_ messageModel: MessageModel?) {
        let tx = chatTransactions.first(where: { $0.txId == messageModel?.id })
        guard isSendingAvailable, tx?.isFake == false else { return }
        
        let message = messages.first(where: { $0.messageId == messageModel?.id })
        guard message?.status != .failed else {
            dialog.send(.warning(String.adamant.reply.failedMessageError))
            return
        }
        
        guard message?.status != .pending else {
            dialog.send(.warning(String.adamant.reply.pendingMessageError))
            return
        }
        
        replyMessage = messageModel
    }
    
    func animateScrollIfNeeded(to messageIndex: Int, visibleIndex: Int?) {
        guard let visibleIndex = visibleIndex else {  return }
        
        let max = max(visibleIndex, messageIndex)
        let min = min(visibleIndex, messageIndex)
        
        guard (max - min) >= minDiffCountForAnimateScroll else {
            isNeedToAnimateScroll = false
            return
        }
        
        isNeedToAnimateScroll = true
    }
    
    func copyMessageAction(_ text: String) {
        UIPasteboard.general.string = text
        dialog.send(.toast(.adamant.alert.copiedToPasteboardNotification))
    }
    
    func copyTextInPartAction(_ text: String) {
        didTapSelectText.send(text)
    }
    
    func reportMessageAction(_ id: String) {
        dialog.send(.reportMessageAlert(id: id))
    }
    
    func removeMessageAction(_ id: String) {
        dialog.send(.removeMessageAlert(id: id))
    }
    
    func reactAction(_ id: String, emoji: String) {
        guard let partnerAddress = chatroom?.partner?.address else { return }
        
        guard chatroom?.partner?.isDummy != true else {
            dialog.send(.dummy(partnerAddress))
            return
        }
        
        Task {
            let message: AdamantMessage = .richMessage(
                payload: RichMessageReaction(
                    reactto_id: id,
                    react_message: emoji
                )
            )
            
            guard await validateSendingMessage(message: message) else { return }
            
            do {
                _ = try await chatsProvider.sendMessage(
                    message,
                    recipientId: partnerAddress,
                    from: chatroom
                )
            } catch {
                await handleMessageSendingError(error: error, sentText: emoji)
            }
        }.stored(in: tasksStorage)
    }
    
    func clearReplyMessage() {
        replyMessage = nil
    }
    
    func clearPickedFiles() {
        filesPicked = nil
    }
    
    func presentMenu(arg: ChatContextMenuArguments) {
        let didSelectEmojiAction: ChatDialogManager.DidSelectEmojiAction = { [weak self] emoji, messageId in
            self?.dialog.send(.dismissMenu)
            
            let emoji = emoji == arg.selectedEmoji
            ? ""
            : emoji
            
            let type: EmojiUpdateType = emoji.isEmpty
            ? .decrement
            : .increment
            
            self?.emojiService.updateFrequentlySelectedEmojis(
                selectedEmoji: emoji,
                type: type
            )
            
            self?.reactAction(messageId, emoji: emoji)
            self?.previousArg = nil
        }
        
        let didPresentMenuAction: ChatDialogManager.ContextMenuAction = { [weak self] messageId in
            self?.hiddenMessageID = messageId
        }
        
        let didDismissMenuAction: ChatDialogManager.ContextMenuAction = { [weak self] _ in
            self?.hiddenMessageID = nil
            self?.layoutIfNeeded.send()
            self?.previousArg = nil
        }
        
        previousArg = arg
        
        let tx = chatTransactions.first(where: { $0.txId == arg.messageId })
        guard tx?.statusEnum == .delivered else { return }
        
        let amount = tx?.amountValue ?? .zero
        if !amount.isZero && !isSendingAvailable {
            return
        }
        
        let presentReactions = isSendingAvailable && tx?.isFake == false
        
        dialog.send(
            .presentMenu(
                presentReactions: presentReactions,
                arg: arg,
                didSelectEmojiDelegate: self,
                didSelectEmojiAction: didSelectEmojiAction,
                didPresentMenuAction: didPresentMenuAction,
                didDismissMenuAction: didDismissMenuAction
            )
        )
    }
    
    func canSendMessage(withText text: String) async -> Bool {
        guard text.count <= maxMessageLenght else {
            dialog.send(.alert(.adamant.chat.messageIsTooBig))
            return false
        }
        
        guard apiServiceCompose.get(.adm)?.hasEnabledNode == true else {
            dialog.send(.alert(ApiServiceError.noEndpointsAvailable(
                nodeGroupName: NodeGroup.adm.name
            ).localizedDescription))
            return false
        }
        
        return true
    }
    
    /// If the user opens the app from the background
    /// update messages to refresh the header dates.
    func refreshDateHeadersIfNeeded() {
        guard !Calendar.current.isDate(Date(), inSameDayAs: lastDateHeaderUpdate) else {
            return
        }
        
        lastDateHeaderUpdate = Date()
        updateMessages(resetLoadingProperty: false)
    }

    func openFile(messageId: String, file: ChatFile) {
        let tx = chatTransactions.first(where: { $0.txId == messageId })
        let message = messages.first(where: { $0.messageId == messageId })
        
        guard let tx = tx,
              tx.statusEnum != .failed
        else {
            dialog.send(.failedMessageAlert(id: messageId, sender: nil))
            return
        }
        
        guard !chatFileService.downloadingFiles.keys.contains(file.file.id),
              !chatFileService.uploadingFiles.contains(file.file.id),
              case let(.file(fileModel)) = message?.content
        else { return }
        
        let chatFiles = fileModel.value.content.fileModel.files
        
        let isPreviewAutoDownloadAllowed = isDownloadAllowed(
            policy: filesStorageProprieties.autoDownloadPreviewPolicy(),
            havePartnerName: havePartnerName
        )
        
        if !isPreviewAutoDownloadAllowed,
           file.previewImage == nil,
           file.file.preview != nil,
           !chatFileService.isDownloadPreviewLimitReached(for: file.file.id) {
            forceDownloadAllFiles(messageId: messageId, files: chatFiles)
            return
        }
        
        guard !file.isCached,
              !filesStorage.isCachedLocally(file.file.id)
        else {
            self.presentFileInFullScreen(id: file.file.id, chatFiles: chatFiles)
            return
        }
        
        guard tx.statusEnum == .delivered else { return }
        
        downloadFile(
            file: file,
            previewDownloadAllowed: true,
            fullMediaDownloadAllowed: true
        )
    }
    
    func downloadContentIfNeeded(
        messageId: String,
        files: [ChatFile]
    ) {
        let tx = chatTransactions.first(where: { $0.txId == messageId })
        
        guard tx?.statusEnum == .delivered || tx?.statusEnum == nil else { return }
        
        let chatFiles = files.filter {
            $0.fileType == .image || $0.fileType == .video
        }
        
        chatFiles.forEach { file in
            Task {
                await chatFileService.autoDownload(
                    file: file,
                    chatroom: chatroom,
                    havePartnerName: havePartnerName,
                    previewDownloadPolicy: filesStorageProprieties.autoDownloadPreviewPolicy(),
                    fullMediaDownloadPolicy: filesStorageProprieties.autoDownloadFullMediaPolicy(),
                    saveEncrypted: filesStorageProprieties.saveFileEncrypted()
                )
            }
        }
    }
    
    func forceDownloadAllFiles(messageId: String, files: [ChatFile]) {
        let isPreviewDownloadAllowed = isDownloadAllowed(
            policy: filesStorageProprieties.autoDownloadPreviewPolicy(),
            havePartnerName: havePartnerName
        )
        
        let isFullMediaDownloadAllowed = isDownloadAllowed(
            policy: filesStorageProprieties.autoDownloadFullMediaPolicy(),
            havePartnerName: havePartnerName
        )
        
        let needToDownload: [ChatFile]
        
        let shouldDownloadFile: (ChatFile) -> Bool = { file in
            !file.isCached || (file.fileType.isMedia && file.previewImage == nil && isPreviewDownloadAllowed)
        }
        
        let previewFiles = files.filter { file in
            (file.fileType == .image || file.fileType == .video) && file.previewImage == nil
        }
        
        let notCachedFiles = files.filter { !$0.isCached }
        
        let downloadPreview: Bool
        let downloadFullMedia: Bool
        
        switch (isPreviewDownloadAllowed, isFullMediaDownloadAllowed) {
        case (true, true):
            needToDownload = files.filter(shouldDownloadFile)
            downloadPreview = true
            downloadFullMedia = true
        case (true, false):
            needToDownload = previewFiles.isEmpty 
            ? notCachedFiles
            : previewFiles
            
            downloadPreview = previewFiles.isEmpty
            ? false
            : true
            
            downloadFullMedia = previewFiles.isEmpty
            ? true
            : false
        case (false, true):
            needToDownload = notCachedFiles.isEmpty 
            ? previewFiles
            : notCachedFiles
            
            downloadPreview = notCachedFiles.isEmpty
            ? true
            : false
            
            downloadFullMedia = notCachedFiles.isEmpty
            ? false
            : true
        case (false, false):
            needToDownload = previewFiles.isEmpty 
            ? notCachedFiles
            : previewFiles
            
            downloadPreview = previewFiles.isEmpty
            ? false
            : true
            
            downloadFullMedia = previewFiles.isEmpty
            ? true
            : false
        }
        
        needToDownload.forEach { file in
            downloadFile(
                file: file,
                previewDownloadAllowed: downloadPreview,
                fullMediaDownloadAllowed: downloadFullMedia
            )
        }
    }
    
    func downloadFile(
        file: ChatFile,
        previewDownloadAllowed: Bool,
        fullMediaDownloadAllowed: Bool
    ) {
        Task { [weak self] in
            try? await self?.chatFileService.downloadFile(
                file: file,
                chatroom: self?.chatroom,
                saveEncrypted: self?.filesStorageProprieties.saveFileEncrypted() ?? true,
                previewDownloadAllowed: previewDownloadAllowed,
                fullMediaDownloadAllowed: fullMediaDownloadAllowed
            )
        }
    }
    
    func presentActionMenu() {
        dialog.send(.actionMenu)
    }
    
    func didSelectMenuAction(_ action: ShareType) {
        if case(.sendTokens) = action {
            presentSendTokensVC.send()
        }
        
        if case(.uploadMedia) = action {
            presentMediaPickerVC.send()
        }
        
        if case(.uploadFile) = action {
            presentDocumentPickerVC.send()
        }
    }
    
    @MainActor
    func processFileResult(_ result: Result<[FileResult], Error>) {
        switch result {
        case .success(let files):
            var oldFiles = filesPicked ?? []
            
            files.forEach { file in
                if !oldFiles.contains(where: { $0.assetId == file.assetId }) {
                    oldFiles.append(file)
                }
            }
            
            if oldFiles.count > FilesConstants.maxFilesCount {
                let numberOfExtraElements = oldFiles.count - FilesConstants.maxFilesCount
                let extraFilesToRemove = oldFiles.prefix(numberOfExtraElements)
                for file in extraFilesToRemove {
                    let urls = [file.url] + (file.previewUrl.map { [$0] } ?? [])
                    filesStorage.removeTempFiles(at: urls)
                }
                
                oldFiles.removeFirst(numberOfExtraElements)
            }
            
            filesPicked = oldFiles
        case .failure(let error):
            dialog.send(.alert(error.localizedDescription))
        }
    }
    
    func presentDialog(progress: Bool) {
        dialog.send(.progress(progress))
    }
    
    func dropSessionUpdated(_ value: Bool) {
        presentDropView.send(value)
    }
    
    func updatePreviewFor(indexes: [IndexPath]) {
        indexes.forEach { index in
            guard let message = messages[safe: index.section],
                  case let .file(model) = message.content
            else { return }
            
            downloadContentIfNeeded(
                messageId: message.messageId,
                files: model.value.content.fileModel.files
            )
        }
    }
}

extension ChatViewModel {
    func getTempOffset(visibleIndex: Int?) -> String? {
        let lastId = tempOffsets.popLast()
        
        guard let visibleIndex = visibleIndex,
              let index = messages.firstIndex(where: { $0.messageId == lastId })
        else {
            return lastId
        }
        
        return index > visibleIndex ? lastId : nil
    }
    
    func appendTempOffset(_ id: String, toId: String) {
        guard let indexFrom = messages.firstIndex(where: { $0.messageId == id }),
              let indexTo = messages.firstIndex(where: { $0.messageId == toId }),
              (indexFrom - indexTo) >= minDiffCountForOffset
        else {
            return
        }
        
        if let index = tempOffsets.firstIndex(of: id) {
            tempOffsets.remove(at: index)
        }
        
        tempOffsets.append(id)
    }
    
    func openPartnerQR() {
        guard let partner = chatroom?.partner,
              isSendingAvailable
        else { return }
        
        didTapPartnerQR.send(partner)
    }
    
    func renamePartner() {
        guard isSendingAvailable else { return }
        
        dialog.send(.renameAlert)
    }
    
    func updatePartnerName() {
        partnerName = chatroom?.getName(addressBookService: addressBookService)
	}

    func updateFiles(_ data: [FileResult]?) {
        if (data?.count ?? .zero) == .zero {
            let previewUrls = filesPicked?.compactMap { $0.previewUrl } ?? []
            let fileUrls = filesPicked?.compactMap { $0.url } ?? []
            
            filesStorage.removeTempFiles(at: previewUrls + fileUrls)
        }
        
        filesPicked = data
    }
    
    func handlePastedImage(_ image: UIImage) {
        do {
            let file = try filesPicker.getFileResult(for: image)
            processFileResult(.success([file]))
        } catch {
            processFileResult(.failure(error))
        }
    }
    
    func checkTopMessage(indexPath: IndexPath) {
        guard let message = messages[safe: indexPath.section],
              let date = message.dateHeader?.string.string,
              message.sentDate != .adamantNullDate
        else { return }
        dateHeader = date
        dateHeaderHidden = false
        hideHeaderTimer?.cancel()
        hideHeaderTimer = nil
    }
    
    func startHideDateTimer() {
        hideHeaderTimer?.cancel()
        hideHeaderTimer = Timer
            .publish(every: delayHideHeaderInSeconds, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.dateHeaderHidden = true
            }
    }
}

extension ChatViewModel: NSFetchedResultsControllerDelegate {
    nonisolated func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        Task { @MainActor in updateTransactions(performFetch: false) }
    }
}

private extension ChatViewModel {
    func sendFiles(with text: String) async throws {
        guard apiServiceCompose.get(.ipfs)?.hasEnabledNode == true else {
            dialog.send(.alert(ApiServiceError.noEndpointsAvailable(
                nodeGroupName: NodeGroup.ipfs.name
            ).localizedDescription))
            return
        }
        
        let replyMessage = replyMessage
        let filesPicked = filesPicked
        
        self.replyMessage = nil
        self.filesPicked = nil
        
        try await chatFileService.sendFile(
            text: text,
            chatroom: chatroom,
            filesPicked: filesPicked,
            replyMessage: replyMessage,
            saveEncrypted: filesStorageProprieties.saveFileEncrypted()
        )
    }
    
    func setupObservers() {
        $inputText
            .removeDuplicates()
            .sink { [weak self] _ in self?.inputTextUpdated() }
            .store(in: &subscriptions)
        
        chatFileService.updateFileFields
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                
                let fileProprieties = FileUpdateProperties(
                    id: data.id,
                    newId: data.newId,
                    fileNonce: data.fileNonce,
                    preview: data.preview,
                    cached: data.cached,
                    downloadStatus: data.downloadStatus,
                    uploading: data.uploading,
                    progress: data.progress,
                    isPreviewDownloadAllowed: nil,
                    isFullMediaDownloadAllowed: nil
                )
                
                self.updateFileFields(
                    &self.messages,
                    fileProprieties: fileProprieties
                )
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantVisibleWalletsService.visibleWallets)
            .sink { @MainActor [weak self] _ in self?.updateAttachmentButtonAvailability() }
            .store(in: &subscriptions)
        
        Task {
            await chatsProvider.stateObserver
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.isHeaderLoading = state == .updating ? true : false
                }
                .store(in: &subscriptions)
        }.stored(in: tasksStorage)
        
        dropInteractionService.onPreparedDataCallback = { [weak self] result in
            Task { @MainActor in
                self?.dropSessionUpdated(false)
                self?.presentDialog(progress: false)
                self?.processFileResult(result)
            }
        }
        
        dropInteractionService.onPreparingDataCallback = { [weak self] in
            Task { @MainActor in
                self?.presentDialog(progress: true)
            }
        }
        
        dropInteractionService.onSessionCallback = { [weak self] fileOnScreen in
            self?.dropSessionUpdated(fileOnScreen)
        }
        
        mediaPickerDelegate.onPreparedDataCallback = { [weak self] result in
            Task { @MainActor in
                self?.presentDialog(progress: false)
                self?.processFileResult(result)
            }
        }
        
        mediaPickerDelegate.onPreparingDataCallback = { [weak self] in
            Task { @MainActor in
                self?.presentDialog(progress: true)
            }
        }
        
        documentPickerDelegate.onPreparedDataCallback = { [weak self] result in
            Task { @MainActor in
                self?.presentDialog(progress: false)
                self?.processFileResult(result)
            }
        }
        
        documentPickerDelegate.onPreparingDataCallback = { [weak self] in
            Task { @MainActor in
                self?.presentDialog(progress: true)
            }
        }
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
        
        let newTransactions = controller?.fetchedObjects ?? []
        let isNewReaction = isNewReaction(old: chatTransactions, new: newTransactions)
        chatTransactions = newTransactions
        
        updateMessages(
            resetLoadingProperty: performFetch,
            completion: isNewReaction
                ? { @Sendable [commitVibro] in commitVibro.send() }
                : {}
        )
    }
    
    func updateMessages(
        resetLoadingProperty: Bool,
        completion: @MainActor @escaping () -> Void = {}
    ) {
        timerSubscription = nil
        
        Task(priority: .userInitiated) { [chatTransactions, sender] in
            defer { completion() }
            var expirationTimestamp: TimeInterval?

            var messages = await chatMessagesListFactory.makeMessages(
                transactions: chatTransactions,
                sender: sender,
                isNeedToLoadMoreMessages: isNeedToLoadMoreMessages,
                expirationTimestamp: &expirationTimestamp
            )
            
            postProcess(messages: &messages)
            
            await setupNewMessages(
                newMessages: messages,
                resetLoadingProperty: resetLoadingProperty,
                expirationTimestamp: expirationTimestamp
            )
            
            // The 'makeMessages' method doesn't include reactions.
            // If the message count is different from the number of transactions, update the chat read status if necessary.
            if messages.count != chatTransactions.count {
                updateChatRead.send()
            }
        }
    }
    
    @MainActor
    func postProcess(messages: inout[ChatMessage]) {
        let indexes = messages.indices.filter {
            messages[$0].getFiles().count > .zero
        }
        
        indexes.forEach { index in
            guard case let .file(model) = messages[index].content else { return }
            
            model.value.content.fileModel.files.forEach { file in
                setupFileFields(file, messages: &messages, index: index)
            }
        }
    }
    
    func setupFileFields(
        _ file: ChatFile,
        messages: inout[ChatMessage],
        index: Int
    ) {
        let fileId = file.file.id
        
        let previewImage = (file.file.preview?.id).flatMap {
            !$0.isEmpty
            ? filesStorage.getPreview(for: $0)
            : nil
        }
        
        let progress = chatFileService.filesLoadingProgress[fileId]
        let downloadStatus = chatFileService.downloadingFiles[fileId] ?? .default
        let cached = filesStorage.isCachedLocally(fileId)
        let isUploading = chatFileService.uploadingFiles.contains(fileId)
        
        let isPreviewDownloadAllowed = isDownloadAllowed(
            policy: filesStorageProprieties.autoDownloadPreviewPolicy(),
            havePartnerName: havePartnerName
        )
        
        let isFullMediaDownloadAllowed = isDownloadAllowed(
            policy: filesStorageProprieties.autoDownloadFullMediaPolicy(),
            havePartnerName: havePartnerName
        )
        
        let fileProprieties = FileUpdateProperties(
            id: file.file.id,
            newId: nil,
            fileNonce: nil,
            preview: .some(previewImage),
            cached: cached,
            downloadStatus: downloadStatus,
            uploading: isUploading,
            progress: progress,
            isPreviewDownloadAllowed: isPreviewDownloadAllowed,
            isFullMediaDownloadAllowed: isFullMediaDownloadAllowed
        )
        
        updateFileMessageFields(for: &messages[index], fileProprieties: fileProprieties)
    }
    
    func setupNewMessages(
        newMessages: [ChatMessage],
        resetLoadingProperty: Bool,
        expirationTimestamp: TimeInterval?
    ) async {
        var newMessages = newMessages
        updateHiddenMessage(&newMessages)
        
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
    
    func handleMessageSendingError(
        error: Error,
        sentText: String,
        filesPicked: [FileResult]? = nil
    ) async {
        switch error as? ChatsProviderError {
        case .messageNotValid:
            inputText = sentText
        case .notEnoughMoneyToSend:
            inputText = sentText
            self.filesPicked = filesPicked
            guard await transfersProvider.hasTransactions else {
                dialog.send(.freeTokenAlert)
                return
            }
        case .accountNotFound, .accountNotInitiated, .dependencyError, .internalError, .networkError, .notLogged, .requestCancelled, .serverError, .transactionNotFound, .invalidTransactionStatus, .none:
            break
        }
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
    
    func updatePartnerInformation() {
        guard let publicKey = chatroom?.partner?.publicKey else {
            return
        }
        
        partnerName = chatroom?.getName(addressBookService: addressBookService)
        havePartnerName = chatroom?.hasPartnerName(addressBookService: addressBookService) ?? false
        
        guard let avatarName = chatroom?.partner?.avatar,
              let avatar = UIImage.asset(named: avatarName)
        else {
            partnerImage = avatarService.avatar(
                for: publicKey,
                size: partnerImageSize
            )
            return
        }
        
        partnerImage = avatar
    }
    
    func updateAttachmentButtonAvailability() {
        let isAnyWalletVisible = walletServiceCompose.getWallets()
            .map { visibleWalletService.isInvisible($0.core) }
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
                   message == String.adamant.sharedErrors.unknownError {
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
    
    func waitForChatLoading(with address: String) async {
        await withUnsafeContinuation { continuation in
            Task {
                let publisher = await chatsProvider.chatLoadingStatusPublisher
                publisher
                    .filter { dict in
                        dict.contains {
                            $0.key == address && $0.value == .loaded
                        }
                    }
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        self?.tempCancellables.removeAll()
                        continuation.resume()
                    }.store(in: &tempCancellables)
            }
        }
    }
    
    // TODO: Post process
    func updateHiddenMessage(_ messages: inout [ChatMessage]) {
        messages.indices.forEach {
            messages[$0].isHidden = messages[$0].id == hiddenMessageID
        }
    }
    
    func updateFileFields(
        _ messages: inout [ChatMessage],
        fileProprieties: FileUpdateProperties
    ) {
        let indexes = messages.indices.filter {
            messages[$0].getFiles().contains { $0.file.id == fileProprieties.id }
        }
        
        guard !indexes.isEmpty else {
            return
        }
        
        indexes.forEach { index in
            updateFileMessageFields(for: &messages[index], fileProprieties: fileProprieties)
        }
    }
    
    func updateFileMessageFields(
        for message: inout ChatMessage,
        fileProprieties: FileUpdateProperties
    ) {
        message.updateFileFields(
            id: fileProprieties.id
        ) { file in
            fileProprieties.newId.map { file.file.id = $0 }
            fileProprieties.fileNonce.map { file.file.nonce = $0 }
            fileProprieties.preview.map { file.previewImage = $0 }
            fileProprieties.cached.map { file.isCached = $0 }
            fileProprieties.uploading.map { file.isUploading = $0 }
            fileProprieties.downloadStatus.map { file.downloadStatus = $0 }
            fileProprieties.progress.map { file.progress = $0 }
            fileProprieties.isPreviewDownloadAllowed.map { file.isPreviewDownloadAllowed = $0 }
            fileProprieties.isFullMediaDownloadAllowed.map { file.isFullMediaDownloadAllowed = $0 }
        } mutateModel: { model in
            model.status = getStatus(from: model)
        }
    }
    
    func getStatus(from model: ChatMediaContainerView.Model) -> FileMessageStatus {
        if model.txStatus == .failed {
            return .failed
        }
        
        if model.content.fileModel.files.first(where: { $0.isBusy }) != nil {
            return .busy
        }
        
        if model.content.fileModel.files.contains(where: {
            !$0.isCached ||
            ($0.isCached
             && $0.file.preview != nil
             && $0.previewImage == nil
             && ($0.fileType == .image || $0.fileType == .video))
        }) {
            let failed = model.content.fileModel.files.contains(where: {
                guard let progress = $0.progress else { return false }
                return progress < 100
            })
            
            return .needToDownload(failed: failed)
        }
        
        return .success
    }
    
    func isNewReaction(old: [ChatTransaction], new: [ChatTransaction]) -> Bool {
        guard
            let processedDate = old.getMostRecentElementDate(),
            let newLastReactionDate = new.getMostRecentReactionDate()
        else { return false }
        
        return newLastReactionDate > processedDate
    }
    
    func presentFileInFullScreen(id: String, chatFiles: [ChatFile]) {
        dialog.send(.progress(true))
        
        let files: [FileResult] = chatFiles.compactMap { file in
            guard file.isCached,
                  !file.isBusy,
                  let fileDTO = try? filesStorage.getFile(with: file.file.id).get()
            else {
                return nil
            }
            
            let data = try? chatFileService.getDecodedData(
                file: fileDTO,
                nonce: file.file.nonce,
                chatroom: chatroom
            )
            
            return FileResult.init(
                assetId: file.file.id,
                url: fileDTO.url,
                type: file.fileType,
                preview: nil,
                previewUrl: nil,
                previewExtension: nil,
                size: file.file.size,
                name: file.file.name,
                extenstion: file.file.extension,
                resolution: nil,
                data: data
            )
        }
      
        dialog.send(.progress(false))
        let index = files.firstIndex(where: { $0.assetId == id }) ?? .zero
        presentDocumentViewerVC.send((files, index))
    }
    
    func isDownloadAllowed(
        policy: DownloadPolicy,
        havePartnerName: Bool
    ) -> Bool {
        switch policy {
        case .everybody:
            return true
        case .nobody:
            return false
        case .contacts:
            return havePartnerName
        }
    }
}

private extension ChatMessage {
    var isHidden: Bool {
        get {
            switch content {
            case let .message(model):
                return model.value.isHidden
            case let .reply(model):
                return model.value.isHidden
            case let .transaction(model):
                return model.value.content.isHidden
            case let .file(model):
                return model.value.content.isHidden
            }
        }
        
        set {
            switch content {
            case let .message(model):
                var model = model.value
                model.isHidden = newValue
                content = .message(.init(value: model))
            case let .reply(model):
                var model = model.value
                model.isHidden = newValue
                content = .reply(.init(value: model))
            case let .transaction(model):
                var model = model.value
                model.content.isHidden = newValue
                content = .transaction(.init(value: model))
            case let .file(model):
                var model = model.value
                model.content.isHidden = newValue
                content = .file(.init(value: model))
            }
        }
    }
    
    func getFiles() -> [ChatFile] {
        guard case let .file(model) = content else { return [] }
        return model.value.content.fileModel.files
    }
    
    mutating func updateFileFields(
        id: String,
        mutateFile: (inout ChatFile) -> Void,
        mutateModel: (inout ChatMediaContainerView.Model) -> Void
    ) {
        guard case let .file(fileModel) = content else { return }
        var model = fileModel.value
        
        guard let index = model.content.fileModel.files.firstIndex(
            where: { $0.file.id == id }
        ) else { return }
        
        let previousValue = model
        
        mutateFile(&model.content.fileModel.files[index])
        mutateModel(&model)
        
        guard model != previousValue else {
            return
        }
        
        content = .file(.init(value: model))
    }
}

private extension Sequence where Element == ChatTransaction {
    func getMostRecentElementDate() -> Date? {
        map { $0.sentDate ?? .adamantNullDate }.max()
    }
    
    func getMostRecentReactionDate() -> Date? {
        compactMap {
            guard
                let tx = $0 as? RichMessageTransaction,
                tx.additionalType == .reaction
            else { return nil }
            
            return $0.sentDate ?? .adamantNullDate
        }.max()
    }
}

extension ChatViewModel: ElegantEmojiPickerDelegate {
    nonisolated func emojiPicker(_ picker: ElegantEmojiPicker, didSelectEmoji emoji: Emoji?) {
        let sendableEmoji = Atomic(emoji)
        
        MainActor.assumeIsolatedSafe {
            dialog.send(.dismissMenu)
            
            guard let previousArg = previousArg else { return }
            
            let emoji = sendableEmoji.value?.emoji == previousArg.selectedEmoji
            ? ""
            : (sendableEmoji.value?.emoji ?? "")
            
            let type: EmojiUpdateType = emoji.isEmpty
            ? .decrement
            : .increment
            
            emojiService.updateFrequentlySelectedEmojis(
                selectedEmoji: emoji,
                type: type
            )
            
            reactAction(previousArg.messageId, emoji: emoji)
        }
    }
}
