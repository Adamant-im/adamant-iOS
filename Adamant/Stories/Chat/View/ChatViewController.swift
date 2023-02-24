//
//  ChatViewController.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import InputBarAccessoryView
import Combine
import UIKit
import SnapKit

@MainActor
final class ChatViewController: MessagesViewController {
    typealias SpinnerCell = MessageCellWrapper<SpinnerView>
    typealias TransactionCell = CollectionCellWrapper<ChatTransactionContainerView>
    typealias SendTransaction = (UIViewController & ComplexTransferViewControllerDelegate) -> Void
    
    private let storedObjects: [AnyObject]
    private let richMessageProviders: [String: RichMessageProvider]
    private var subscriptions = Set<AnyCancellable>()
    private var topMessageId: String?
    private var bottomMessageId: String?
    private var messagesLoaded = false
    private var isScrollPositionNearlyTheBottom = true
    private var viewAppeared = false
    
    let viewModel: ChatViewModel
    
    private lazy var inputBar = ChatInputBar()
    private lazy var loadingView = LoadingView()
    private lazy var scrollDownButton = makeScrollDownButton()
    private lazy var chatMessagesCollectionView = makeChatMessagesCollectionView()
    
    private var admService: WalletServiceWithSend?
    
    // swiftlint:disable unused_setter_value
    override var messageInputBar: InputBarAccessoryView {
        get { inputBar }
        set { assertionFailure("Do not set messageInputBar") }
    }
    
    // swiftlint:disable unused_setter_value
    override var messagesCollectionView: MessagesCollectionView {
        get { chatMessagesCollectionView }
        set { assertionFailure("Do not set messagesCollectionView") }
    }
    
    init(
        viewModel: ChatViewModel,
        richMessageProviders: [String: RichMessageProvider],
        storedObjects: [AnyObject],
        sendTransaction: @escaping SendTransaction,
        admService: WalletServiceWithSend?
    ) {
        self.viewModel = viewModel
        self.storedObjects = storedObjects
        self.richMessageProviders = richMessageProviders
        self.admService = admService
        super.init(nibName: nil, bundle: nil)
        inputBar.onAttachmentButtonTap = { [weak self] in self.map { sendTransaction($0) } }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .adamant.backgroundColor
        messagesCollectionView.backgroundColor = .adamant.backgroundColor
        messagesCollectionView.backgroundView?.backgroundColor = .adamant.backgroundColor
        chatMessagesCollectionView.fixedBottomOffset = .zero
        maintainPositionOnInputBarHeightChanged = true
        configureMessageActions()
        configureHeader()
        configureLayout()
        setupObservers()
        viewModel.loadFirstMessagesIfNeeded()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateIsScrollPositionNearlyTheBottom()
        updateScrollDownButtonVisibility()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        chatMessagesCollectionView.setFullBottomInset(
            view.bounds.height - inputContainerView.frame.minY
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        defer { viewAppeared = true }
        inputBar.isUserInteractionEnabled = true
        chatMessagesCollectionView.fixedBottomOffset = nil
        
        guard isMacOS, !viewAppeared else { return }
        focusInputBarWithoutAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inputBar.isUserInteractionEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.preserveMessage(inputBar.text)
        viewModel.saveChatOffset(
            isScrollPositionNearlyTheBottom
            ? nil
            : chatMessagesCollectionView.bottomOffset
        )
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
        guard indexPath.section < 4 else { return }
        viewModel.loadMoreMessagesIfNeeded()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        updateIsScrollPositionNearlyTheBottom()
        updateScrollDownButtonVisibility()
    }
}

// MARK: Delegate Protocols

extension ChatViewController: ComplexTransferViewControllerDelegate {
    func complexTransferViewController(
        _: ComplexTransferViewController,
        didFinishWithTransfer transfer: TransactionDetails?,
        detailsViewController: UIViewController?
    ) {
        DispatchQueue.onMainAsync { [self] in
            dismissTransferViewController(
                andPresent: detailsViewController,
                didFinishWithTransfer: transfer
            )
        }
    }
}

extension ChatViewController: TransferViewControllerDelegate {
    func transferViewController(
        _: TransferViewControllerBase,
        didFinishWithTransfer transfer: TransactionDetails?,
        detailsViewController: UIViewController?
    ) {
        DispatchQueue.onMainAsync { [self] in
            dismissTransferViewController(
                andPresent: detailsViewController,
                didFinishWithTransfer: transfer
            )
        }
    }
}

// MARK: Mac OS HotKeys

extension ChatViewController {
    override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(onEnterClick))
        ]
        commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        return commands
    }
}

// MARK: Observers

private extension ChatViewController {
    func setupObservers() {
        NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification, object: inputBar.inputTextView)
            .sink { [weak self] _ in self?.inputTextUpdated() }
            .store(in: &subscriptions)
        
        viewModel.$messages
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateMessages() }
            .store(in: &subscriptions)
        
        viewModel.$fullscreenLoading
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateFullscreenLoadingView() }
            .store(in: &subscriptions)
        
        viewModel.$inputText
            .removeDuplicates()
            .assign(to: \.text, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.$isSendingAvailable
            .removeDuplicates()
            .assign(to: \.isEnabled, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.$fee
            .removeDuplicates()
            .assign(to: \.fee, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.didTapTransfer
            .sink { [weak self] in self?.didTapTransfer(id: $0) }
            .store(in: &subscriptions)
        
        viewModel.$partnerName
            .removeDuplicates()
            .assign(to: \.title, on: navigationItem)
            .store(in: &subscriptions)
        
        viewModel.closeScreen
            .sink { [weak self] in self?.close() }
            .store(in: &subscriptions)
        
        viewModel.$isAttachmentButtonAvailable
            .removeDuplicates()
            .assign(to: \.isAttachmentButtonEnabled, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.didTapAdmChat
            .sink { [weak self] in self?.didTapAdmChat(with: $0, message: $1) }
            .store(in: &subscriptions)
        
        viewModel.didTapAdmSend
            .sink { [weak self] in self?.didTapAdmSend(to: $0) }
            .store(in: &subscriptions)
    }
}

// MARK: Configuration

private extension ChatViewController {
    func configureMessageActions() {
        UIMenuController.shared.menuItems = [
            .init(
                title: .adamantLocalized.chat.remove,
                action: #selector(MessageCollectionViewCell.remove)
            ),
            .init(
                title: .adamantLocalized.chat.report,
                action: #selector(MessageCollectionViewCell.report)
            )
        ]
    }
    
    func configureLayout() {
        view.addSubview(scrollDownButton)
        scrollDownButton.snp.makeConstraints { [unowned inputBar] in
            $0.trailing.equalToSuperview().inset(scrollDownButtonInset)
            $0.bottom.equalTo(inputBar.snp.top).offset(-scrollDownButtonInset)
            $0.size.equalTo(30)
        }
        
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    func configureHeader() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = .init(
            title: "•••",
            style: .plain,
            target: self,
            action: #selector(showMenu)
        )
    }
}

// MARK: Content updating

private extension ChatViewController {
    func updateIsScrollPositionNearlyTheBottom() {
        let oldValue = isScrollPositionNearlyTheBottom
        isScrollPositionNearlyTheBottom = chatMessagesCollectionView.bottomOffset < 150
        
        guard oldValue != isScrollPositionNearlyTheBottom else { return }
        checkIsChatWasRead()
    }
    
    func updateMessages() {
        defer { checkIsChatWasRead() }
        chatMessagesCollectionView.reloadData(newModels: viewModel.messages)
        scrollDownOnNewMessageIfNeeded(previousBottomMessageId: bottomMessageId)
        bottomMessageId = viewModel.messages.last?.messageId
        
        guard !messagesLoaded, !viewModel.messages.isEmpty else { return }
        viewModel.startPosition.map { setupStartPosition($0) }
        messagesLoaded = true
    }
    
    func updateFullscreenLoadingView() {
        guard loadingView.isHidden == viewModel.fullscreenLoading else { return }
        loadingView.isHidden = !viewModel.fullscreenLoading
        
        if viewModel.fullscreenLoading {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }
    
    func updateScrollDownButtonVisibility() {
        scrollDownButton.isHidden = isScrollPositionNearlyTheBottom
    }
}

// MARK: Making entities

private extension ChatViewController {
    func makeScrollDownButton() -> ChatScrollDownButton {
        let button = ChatScrollDownButton()
        button.action = { [weak messagesCollectionView] in
            messagesCollectionView?.scrollToLastItem()
        }
        
        return button
    }
    
    func makeChatMessagesCollectionView() -> ChatMessagesCollectionView {
        let collection = ChatMessagesCollectionView()
        collection.refreshControl = ChatRefreshMock()
        collection.register(TransactionCell.self)
        collection.register(
            SpinnerCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )
        
        collection.removeMessageAction = { [weak self] indexPath in
            guard let id = self?.getMessageIdByIndexPath(indexPath) else { return }
            self?.viewModel.dialog.send(.removeMessageAlert(id: id))
        }
        
        collection.reportMessageAction = { [weak self] indexPath in
            guard let id = self?.getMessageIdByIndexPath(indexPath) else { return }
            self?.viewModel.dialog.send(.reportMessageAlert(id: id))
        }
        
        return collection
    }
}

// MARK: Other

private extension ChatViewController {
    func focusInputBarWithoutAnimation() {
        // "becomeFirstResponder()" causes content animation on start without this fix
        Task { @MainActor in
            await Task.sleep(interval: .zero)
            messageInputBar.inputTextView.becomeFirstResponder()
        }
    }
    
    func dismissTransferViewController(
        andPresent viewController: UIViewController?,
        didFinishWithTransfer: TransactionDetails?
    ) {
        if didFinishWithTransfer != nil {
            messagesCollectionView.scrollToLastItem()
        }

        dismiss(animated: true)
        guard let detailsViewController = viewController else { return }
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    func checkIsChatWasRead() {
        guard isScrollPositionNearlyTheBottom, messagesLoaded else { return }
        viewModel.entireChatWasRead()
    }
    
    @MainActor
    func setupStartPosition(_ position: ChatStartPosition) {
        chatMessagesCollectionView.fixedBottomOffset = nil
        
        switch position {
        case let .offset(offset):
            chatMessagesCollectionView.setBottomOffset(offset, safely: viewAppeared)
        case let .messageId(id):
            guard let index = viewModel.messages.firstIndex(where: { $0.messageId == id})
            else { return }
            
            messagesCollectionView.scrollToItem(
                at: .init(item: .zero, section: index),
                at: [.centeredVertically, .centeredHorizontally],
                animated: false
            )
        }
        
        guard !viewAppeared else { return }
        chatMessagesCollectionView.fixedBottomOffset = chatMessagesCollectionView.bottomOffset
    }
    
    func scrollDownOnNewMessageIfNeeded(previousBottomMessageId: String?) {
        let messages = viewModel.messages
        
        guard
            let previousBottomMessageId = previousBottomMessageId,
            let index = messages.firstIndex(where: { $0.id == previousBottomMessageId }),
            index < messages.count - 1,
            isScrollPositionNearlyTheBottom
                || messages.last?.sender.senderId == viewModel.sender.senderId
                && messages.last?.status == .pending
        else { return }
        
        messagesCollectionView.scrollToLastItem()
    }
    
    @objc func showMenu(_ sender: UIBarButtonItem) {
        viewModel.dialog.send(.menu(sender: sender))
    }
    
    func inputTextUpdated() {
        viewModel.inputText = inputBar.text
    }
    
    func didTapTransfer(id: String) {
        guard
            let transaction = viewModel.chatTransactions.first(
                where: { $0.chatMessageId == id }
            )
        else { return }
        
        switch transaction {
        case let transaction as TransferTransaction:
            didTapTransferTransaction(transaction)
        case let transaction as RichMessageTransaction:
            didTapRichMessageTransaction(transaction)
        default:
            return
        }
    }
    
    func didTapTransferTransaction(_ transaction: TransferTransaction) {
        guard
            let provider = richMessageProviders[AdmWalletService.richMessageType]
                as? AdmWalletService
        else { return }
        
        provider.richMessageTapped(for: transaction, in: self)
    }
    
    func didTapRichMessageTransaction(_ transaction: RichMessageTransaction) {
        guard
            let type = transaction.richType,
            let provider = richMessageProviders[type]
        else { return }
        
        switch transaction.transactionStatus {
        case .dublicate:
            viewModel.dialog.send(.alert(.adamantLocalized.sharedErrors.duplicatedTransaction))
        case .failed:
            viewModel.dialog.send(.alert(.adamantLocalized.sharedErrors.inconsistentTransaction))
        case .notInitiated, .pending, .success, .updating, .warning, .none:
            provider.richMessageTapped(for: transaction, in: self)
        }
    }
    
    @objc func onEnterClick() {
        if messageInputBar.inputTextView.isFirstResponder {
            messageInputBar.didSelectSendButton()
        } else {
            messageInputBar.inputTextView.becomeFirstResponder()
        }
    }
    
    func getMessageIdByIndexPath(_ indexPath: IndexPath) -> String? {
        messagesCollectionView.messagesDataSource?.messageForItem(
            at: indexPath,
            in: messagesCollectionView
        ).messageId
    }
 
    // TODO: Use coordinator
    
    func close() {
        let navVC = tabBarController?
            .selectedViewController?
            .children
            .first as? UINavigationController
        
        if let navVC = navVC {
            navVC.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: Markdown

private extension ChatViewController {
    func didTapAdmChat(with chatroom: Chatroom, message: String?) {
        guard let chatlistVC = self.navigationController?.viewControllers.first as? ChatListViewController
        else {
            return
        }
        
        let vc = chatlistVC.chatViewController(for: chatroom)
        if let message = message {
            vc.messageInputBar.inputTextView.text = message
            vc.viewModel.inputText = message
        }
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func didTapAdmSend(to adm: AdamantAddress) {
        guard let vc = admService?.transferViewController() else { return }
        if let v = vc as? TransferViewControllerBase {
            v.recipientAddress = adm.address
            v.recipientName = adm.name
            v.delegate = self
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

private let scrollDownButtonInset: CGFloat = 20
