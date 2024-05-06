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
import CommonKit
import AdvancedContextMenuKit
import ElegantEmojiPicker
import FilesPickerKit

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
    private let richTransactionStatusService: TransactionStatusService
    private let chatCacheService: ChatCacheService
    private let walletServiceCompose: WalletServiceCompose
    private let avatarService: AvatarService
    private let emojiService: EmojiService
    private let chatPreservation: ChatPreservationProtocol
    private let filesStorage: FilesStorageProtocol
    private let chatFileService: ChatFileProtocol
    private let filesStorageProprieties: FilesStorageProprietiesProtocol
    
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
    private let minDiffCountForOffset = 5
    private let minDiffCountForAnimateScroll = 20
    private let partnerImageSize: CGFloat = 25
    private let maxMessageLenght: Int = 10000
    private var previousArg: ChatContextMenuArguments?
    private var havePartnerName: Bool = false
    
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
    
    private var downloadingFilesID: [String] = [] {
        didSet { updateDownloadingFiles(&messages) }
    }
    
    private var uploadingFilesIDs: [String] = [] {
        didSet { updateUploadingFiles(&messages) }
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
        richTransactionStatusService: TransactionStatusService,
        chatCacheService: ChatCacheService,
        walletServiceCompose: WalletServiceCompose,
        avatarService: AvatarService,
        chatMessagesListViewModel: ChatMessagesListViewModel,
        emojiService: EmojiService,
        chatPreservation: ChatPreservationProtocol,
        filesStorage: FilesStorageProtocol,
        chatFileService: ChatFileProtocol,
        filesStorageProprieties: FilesStorageProprietiesProtocol
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
        guard !inputText.isEmpty && replyMessage == nil else { return }
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
        
        if filesPicked?.count ?? .zero > .zero {
            Task {
                let replyMessage = replyMessage
                let filesPicked = filesPicked
                
                self.replyMessage = nil
                self.filesPicked = nil
                
                do {
                    try await chatFileService.sendFile(
                        text: text,
                        chatroom: chatroom,
                        filesPicked: filesPicked,
                        replyMessage: replyMessage
                    )
                } catch {
                    await handleMessageSendingError(error: error, sentText: text)
                }
                
            }
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
            
            if case (.file) = message?.content {
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
    
    func canSendMessage(withText text: String) -> Bool {
        guard text.count <= maxMessageLenght else {
            dialog.send(.alert(.adamant.chat.messageIsTooBig))
            return false
        }
        
        return true
    }
    
    func openFile(messageId: String, file: ChatFile, isFromCurrentSender: Bool) {
        let tx = chatTransactions.first(where: { $0.txId == messageId })
        let message = messages.first(where: { $0.messageId == messageId })
        
        guard tx?.statusEnum == .delivered,
              !downloadingFilesID.contains(file.file.id),
              case let(.file(fileModel)) = message?.content
        else { return }
        
        guard !file.isCached else {
            do {
                _ = try filesStorage.getFileURL(with: file.file.id)

                let chatFiles = fileModel.value.content.fileModel.files
                
                let files: [FileResult] = chatFiles.compactMap { file in
                    guard file.isCached,
                          let url = try? filesStorage.getFileURL(with: file.file.id) else {
                        return nil
                    }
                    
                    return FileResult.init(
                        assetId: file.file.id,
                        url: url,
                        type: file.fileType,
                        preview: nil,
                        previewUrl: nil,
                        size: file.file.size,
                        name: file.file.name,
                        extenstion: file.file.type,
                        resolution: nil
                    )
                }
              
                let index = files.firstIndex(where: { $0.assetId == file.file.id }) ?? .zero
                presentDocumentViewerVC.send((files, index))
            } catch {
                dialog.send(.alert(error.localizedDescription))
            }
            
            return
        }
        
        Task { [weak self] in
            do {
                try await self?.chatFileService.downloadFile(
                    file: file,
                    isFromCurrentSender: isFromCurrentSender,
                    chatroom: self?.chatroom
                )
            } catch {
                self?.dialog.send(.alert(error.localizedDescription))
            }
        }
    }
    
    func downloadPreviewIfNeeded(
        messageId: String,
        file: ChatFile,
        isFromCurrentSender: Bool
    ) {
        let tx = chatTransactions.first(where: { $0.txId == messageId })
        let message = messages.first(where: { $0.messageId == messageId })
        
        guard let message = message,
              tx?.statusEnum == .delivered || (message.status != .failed && message.status != .pending),
              (filesStorageProprieties.autoDownloadPreviewPolicy() != .nobody ||
                filesStorageProprieties.autoDownloadFullMediaPolicy() != .nobody)
        else { return }
        
        chatFileService.autoDownload(
            file: file,
            isFromCurrentSender: isFromCurrentSender,
            chatroom: chatroom,
            havePartnerName: havePartnerName,
            previewDownloadPolicy: filesStorageProprieties.autoDownloadPreviewPolicy(),
            fullMediaDownloadPolicy: filesStorageProprieties.autoDownloadFullMediaPolicy()
        )
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
    
    func updateFiles(_ data: [FileResult]?) {
        if (data?.count ?? .zero) == .zero {
            let previewUrls = filesPicked?.compactMap { $0.previewUrl } ?? []
            let fileUrls = filesPicked?.compactMap { $0.url } ?? []
            
            filesStorage.removeTempFiles(at: previewUrls + fileUrls)
        }
        
        filesPicked = data
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
        
        chatFileService.downloadingFilesIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.downloadingFilesID = data
            }
            .store(in: &subscriptions)
        
        chatFileService.uploadingFilesIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.uploadingFilesIDs = data
            }
            .store(in: &subscriptions)
        
        chatFileService.updateFileFields
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                
                self.updateFileFields(
                    &self.messages,
                    id: data.id,
                    preview: data.preview,
                    needToUpdatePeview: true,
                    cached: data.cached
                )
            }
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
        
        let newTransactions = controller?.fetchedObjects ?? []
        let isNewReaction = isNewReaction(old: chatTransactions, new: newTransactions)
        chatTransactions = newTransactions
        
        updateMessages(
            resetLoadingProperty: performFetch,
            completion: isNewReaction
                ? { [commitVibro] in commitVibro.send() }
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

            let messages = await chatMessagesListFactory.makeMessages(
                transactions: chatTransactions,
                sender: sender,
                isNeedToLoadMoreMessages: isNeedToLoadMoreMessages,
                expirationTimestamp: &expirationTimestamp,
                uploadingFilesIDs: uploadingFilesIDs,
                downloadingFilesIDs: downloadingFilesID
            )
            
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
    
    func updatePartnerInformation() {
        guard let publicKey = chatroom?.partner?.publicKey else {
            return
        }
        
        partnerName = chatroom?.getName(addressBookService: addressBookService)
        havePartnerName = chatroom?.havePartnerName(addressBookService: addressBookService) ?? false
        
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
                await chatsProvider.chatLoadingStatusPublisher
                    .filter { $0.contains(
                        where: {
                            $0.key == address && $0.value == .loaded
                        })
                    }
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        self?.tempCancellables.removeAll()
                        continuation.resume()
                    }.store(in: &tempCancellables)
            }
        }
    }
    
    func updateHiddenMessage(_ messages: inout [ChatMessage]) {
        messages.indices.forEach {
            messages[$0].isHidden = messages[$0].id == hiddenMessageID
        }
    }
    
    func updateDownloadingFiles(_ messages: inout [ChatMessage]) {
        messages.indices.forEach { index in
            messages[index].getFiles().forEach { file in
                messages[index].updateFields(
                    id: file.file.id,
                    preview: nil,
                    needToUpdatePeview: false,
                    isDownloading: downloadingFilesID.contains(file.file.id)
                )
            }
        }
    }
    
    func updateUploadingFiles(_ messages: inout [ChatMessage]) {
        messages.indices.forEach { index in
            messages[index].getFiles().forEach { file in
                messages[index].updateFields(
                    id: file.file.id,
                    preview: nil,
                    needToUpdatePeview: false,
                    isUploading: uploadingFilesIDs.contains(file.file.id)
                )
            }
        }
    }
    
    func updateFileFields(
        _ messages: inout [ChatMessage],
        id oldId: String,
        newId: String? = nil,
        preview: UIImage?,
        needToUpdatePeview: Bool,
        cached: Bool? = nil,
        isUploading: Bool? = nil,
        isDownloading: Bool? = nil
    ) {
        messages.indices.forEach { index in
            messages[index].updateFields(
                id: oldId,
                newId: newId,
                preview: preview, 
                needToUpdatePeview: needToUpdatePeview,
                cached: cached,
                isUploading: isUploading,
                isDownloading: isDownloading
            )
        }
    }
    
    func isNewReaction(old: [ChatTransaction], new: [ChatTransaction]) -> Bool {
        guard
            let processedDate = old.getMostRecentElementDate(),
            let newLastReactionDate = new.getMostRecentReactionDate()
        else { return false }
        
        return newLastReactionDate > processedDate
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
    
    mutating func updateFields(
        id oldId: String,
        newId: String? = nil,
        preview: UIImage?,
        needToUpdatePeview: Bool,
        cached: Bool? = nil,
        isUploading: Bool? = nil,
        isDownloading: Bool? = nil
    ) {
        guard case let .file(fileModel) = content else { return }
        var model = fileModel.value
        
        guard let index = model.content.fileModel.files.firstIndex(
            where: { $0.file.id == oldId }
        ) else { return }
        
        if let newId = newId {
            model.content.fileModel.files[index].file.id = newId
        }
        if let value = cached {
            model.content.fileModel.files[index].isCached = value
        }
        if let value = isUploading {
            model.content.fileModel.files[index].isUploading = value
        }
        if let value = isDownloading {
            model.content.fileModel.files[index].isDownloading = value
        }
        if needToUpdatePeview {
            model.content.fileModel.files[index].previewImage = preview
        }

        guard model != fileModel.value else {
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
    func emojiPicker(_ picker: ElegantEmojiPicker, didSelectEmoji emoji: Emoji?) {
        dialog.send(.dismissMenu)
        
        guard let previousArg = previousArg else { return }
        
        let emoji = emoji?.emoji == previousArg.selectedEmoji
        ? ""
        : (emoji?.emoji ?? "")
        
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
