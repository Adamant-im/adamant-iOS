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
    typealias SendTransaction = ( _ parentVC: UIViewController & ComplexTransferViewControllerDelegate, _ replyToMessageId: String?) -> Void
    
    // MARK: Dependencies
    
    private let storedObjects: [AnyObject]
    private let richMessageProviders: [String: RichMessageProvider]
    private let admService: AdmWalletService?
    
    let viewModel: ChatViewModel
    
    // MARK: Properties
    
    private var subscriptions = Set<AnyCancellable>()
    private var topMessageId: String?
    private var bottomMessageId: String?
    private var messagesLoaded = false
    private var isScrollPositionNearlyTheBottom = true
    private var viewAppeared = false
    
    private lazy var inputBar = ChatInputBar()
    private lazy var loadingView = LoadingView()
    private lazy var scrollDownButton = makeScrollDownButton()
    private lazy var chatMessagesCollectionView = makeChatMessagesCollectionView()
    private lazy var replyView = ReplyView()
    
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
    
    private lazy var updatingIndicatorView: UpdatingIndicatorView = {
        let view = UpdatingIndicatorView(title: "", titleType: .small)
        return view
    }()
    
    init(
        viewModel: ChatViewModel,
        richMessageProviders: [String: RichMessageProvider],
        storedObjects: [AnyObject],
        sendTransaction: @escaping SendTransaction,
        admService: AdmWalletService?
    ) {
        self.viewModel = viewModel
        self.storedObjects = storedObjects
        self.richMessageProviders = richMessageProviders
        self.admService = admService
        super.init(nibName: nil, bundle: nil)
        inputBar.onAttachmentButtonTap = { [weak self] in
            self.map { sendTransaction($0, viewModel.replyMessage?.id) }
            self?.processSwipeMessage(nil)
        }
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
        navigationItem.titleView = updatingIndicatorView
        configureMessageActions()
        configureHeader()
        configureLayout()
        configureReplyView()
        configureGesture()
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

extension ChatViewController {
    override func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let velocity = panGesture.velocity(in: messagesCollectionView)
        return abs(velocity.x) > abs(velocity.y)
    }
    
    private func swipeStateAction(_ state: SwipeableView.State) {
        if state == .began {
            messagesCollectionView.setContentOffset(messagesCollectionView.contentOffset, animated: false)
            messagesCollectionView.isScrollEnabled = false
        }
        
        if state == .ended {
            messagesCollectionView.isScrollEnabled = true
            messagesCollectionView.keyboardDismissMode = .interactive
        }
    }
}

// MARK: Delegate Protocols

extension ChatViewController: ComplexTransferViewControllerDelegate {
    func complexTransferViewController(
        _: ComplexTransferViewController,
        didFinishWithTransfer transfer: TransactionDetails?,
        detailsViewController: UIViewController?
    ) {
        dismissTransferViewController(
            andPresent: detailsViewController,
            didFinishWithTransfer: transfer
        )
    }
}

extension ChatViewController: TransferViewControllerDelegate {
    func transferViewController(
        _: TransferViewControllerBase,
        didFinishWithTransfer transfer: TransactionDetails?,
        detailsViewController: UIViewController?
    ) {
        dismissTransferViewController(
            andPresent: detailsViewController,
            didFinishWithTransfer: transfer
        )
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
        
        viewModel.$partnerName
            .sink { [weak self] in self?.updatingIndicatorView.updateTitle(title: $0) }
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
        
        viewModel.$isHeaderLoading
            .removeDuplicates()
            .sink { [weak self] in
                if $0 {
                    self?.updatingIndicatorView.startAnimate()
                } else {
                    self?.updatingIndicatorView.stopAnimate()
                }
            }
            .store(in: &subscriptions)
        
        viewModel.$replyMessage
            .sink { [weak self] in self?.processSwipeMessage($0) }
            .store(in: &subscriptions)
        
        viewModel.$scrollToMessage
            .sink { [weak self] in
                guard let toId = $0,
                      let fromId = $1
                else { return }
                
                if self?.isScrollPositionNearlyTheBottom != true {
                    if let index = self?.viewModel.tempOffsets.firstIndex(of: fromId) {
                        self?.viewModel.tempOffsets.remove(at: index)
                    }
                    self?.viewModel.tempOffsets.append(fromId)
                }
                self?.scrollToPosition(.messageId(toId), animated: true)
            }
            .store(in: &subscriptions)
        
        viewModel.$swipeState
            .sink { [weak self] in self?.swipeStateAction($0) }
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
    
    func configureReplyView() {
        replyView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        
        replyView.closeAction = { [weak self] in
            self?.viewModel.replyMessage = nil
        }
    }
    
    func configureGesture() {
        let panGesture = UIPanGestureRecognizer()
        panGesture.delegate = self
        messagesCollectionView.addGestureRecognizer(panGesture)
        messagesCollectionView.clipsToBounds = false
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
        chatMessagesCollectionView.reloadData(newIds: viewModel.messages.map { $0.id })
        scrollDownOnNewMessageIfNeeded(previousBottomMessageId: bottomMessageId)
        bottomMessageId = viewModel.messages.last?.messageId
        
        guard !messagesLoaded, !viewModel.messages.isEmpty else { return }
        viewModel.startPosition.map { scrollToPosition($0) }
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
        button.action = { [weak self] in
            guard let id = self?.viewModel.tempOffsets.popLast() else {
                self?.messagesCollectionView.scrollToBottom(animated: true)
                return
            }
            self?.scrollToPosition(.messageId(id), animated: true)
        }
        
        return button
    }
    
    func makeChatMessagesCollectionView() -> ChatMessagesCollectionView {
        let collection = ChatMessagesCollectionView()
        collection.refreshControl = ChatRefreshMock()
        collection.register(TransactionCell.self)
        collection.register(ChatMessageCell.self)
        collection.register(ChatMessageReplyCell.self)
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
        Task {
            await Task.sleep(interval: .zero)
            messageInputBar.inputTextView.becomeFirstResponder()
        }
    }
    
    func dismissTransferViewController(
        andPresent viewController: UIViewController?,
        didFinishWithTransfer: TransactionDetails?
    ) {
        if didFinishWithTransfer != nil {
            messagesCollectionView.scrollToBottom(animated: true)
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
    func scrollToPosition(_ position: ChatStartPosition, animated: Bool = false) {
        chatMessagesCollectionView.fixedBottomOffset = nil
        
        switch position {
        case let .offset(offset):
            chatMessagesCollectionView.setBottomOffset(offset, safely: viewAppeared)
        case let .messageId(id):
            guard let index = viewModel.messages.firstIndex(where: { $0.messageId == id})
            else { break }
            
            messagesCollectionView.scrollToItem(
                at: .init(item: .zero, section: index),
                at: [.centeredVertically, .centeredHorizontally],
                animated: animated
            )
            
            viewModel.needToAnimateCellIndex = index
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
        
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    @objc func showMenu(_ sender: UIBarButtonItem) {
        viewModel.dialog.send(.menu(sender: sender))
    }
    
    func inputTextUpdated() {
        viewModel.inputText = inputBar.text
    }
    
    func processSwipeMessage(_ message: MessageModel?) {
        guard let message = message else {
            closeReplyView()
            return
        }
        
        if !messageInputBar.topStackView.subviews.contains(replyView) {
            UIView.transition(
                with: messageInputBar.topStackView,
                duration: 0.25,
                options: [.transitionCrossDissolve],
                animations: {
                    self.messageInputBar.topStackView.addArrangedSubview(self.replyView)
                })
            messageInputBar.inputTextView.becomeFirstResponder()
        }
        
        replyView.update(with: message)
    }
    
    func closeReplyView() {
        replyView.removeFromSuperview()
        messageInputBar.invalidateIntrinsicContentSize()
        messageInputBar.layoutContainerViewIfNeeded()
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
        admService?.richMessageTapped(for: transaction, in: self)
    }
    
    func didTapRichMessageTransaction(_ transaction: RichMessageTransaction) {
        guard
            let type = transaction.richType,
            let provider = richMessageProviders[type]
        else { return }
        
        switch transaction.transactionStatus {
        case .failed:
            viewModel.dialog.send(.alert(.adamantLocalized.sharedErrors.inconsistentTransaction))
        case .notInitiated, .pending, .success, .none, .inconsistent, .registered, .noNetwork, .noNetworkFinal:
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
        var chatlistVC: ChatListViewController?
        
        if let nav = splitViewController?.viewControllers.first as? UINavigationController,
           let vc = nav.viewControllers.first as? ChatListViewController {
            chatlistVC = vc
        }
        
        if let vc = navigationController?.viewControllers.first as? ChatListViewController {
            chatlistVC = vc
        }
        
        guard let chatlistVC = chatlistVC else { return }
        
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

// MARK: Animate cell

extension ChatViewController {
    internal override func scrollViewDidEndScrollingAnimation(_: UIScrollView) {
        guard let index = viewModel.needToAnimateCellIndex else { return }
        
        let cell = messagesCollectionView.cellForItem(at: .init(item: .zero, section: index))
        cell?.isSelected = true
        
        Task {
            await Task.sleep(interval: 1.0)
            cell?.isSelected = false
        }
        
        viewModel.needToAnimateCellIndex = nil
    }
}

private let scrollDownButtonInset: CGFloat = 20
private let messagePadding: CGFloat = 12
private var replyAction: Bool = false
private var canReplyVibrate: Bool = true
private var oldContentOffset: CGPoint?
