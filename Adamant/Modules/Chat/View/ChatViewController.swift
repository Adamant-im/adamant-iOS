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
import CommonKit
import FilesStorageKit
import PhotosUI
import FilesPickerKit
import QuickLook

@MainActor
final class ChatViewController: MessagesViewController {
    typealias SpinnerCell = MessageCellWrapper<SpinnerView>
    typealias SendTransaction = @MainActor (
        _ parentVC: UIViewController & ComplexTransferViewControllerDelegate,
        _ replyToMessageId: String?
    ) -> Void
    
    // MARK: Dependencies
    
    private let storedObjects: [AnyObject]
    private let walletServiceCompose: WalletServiceCompose
    private let admWalletService: WalletService?
    private let screensFactory: ScreensFactory
    
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
    private lazy var filesToolbarView = FilesToolbarView()
    private lazy var chatDropView = ChatDropView()
    private lazy var dateHeaderLabel = EdgeInsetLabel(
        font: .adamantPrimary(ofSize: 13),
        textColor: .adamant.textColor,
        numberOfLines: 1
    )
    
    private var sendTransaction: SendTransaction
    
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
        view.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(self.view.bounds.width - 150)
            make.height.equalTo(45)
        }
        return view
    }()
    
    private lazy var chatKeyboardManager: ChatKeyboardManager = {
        let data = ChatKeyboardManager(scrollView: messagesCollectionView)
        return data
    }()
    
    init(
        viewModel: ChatViewModel,
        walletServiceCompose: WalletServiceCompose,
        storedObjects: [AnyObject],
        admWalletService: WalletService?,
        screensFactory: ScreensFactory,
        sendTransaction: @escaping SendTransaction
    ) {
        self.viewModel = viewModel
        self.storedObjects = storedObjects
        self.walletServiceCompose = walletServiceCompose
        self.admWalletService = admWalletService
        self.screensFactory = screensFactory
        self.sendTransaction = sendTransaction
        super.init(nibName: nil, bundle: nil)
        inputBar.onAttachmentButtonTap = { [weak self] in
            self?.viewModel.presentActionMenu()
        }
        inputBar.onImagePasted = { [weak self] image in
            self?.viewModel.handlePastedImage(image)
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
        configureHeader()
        configureLayout()
        configureReplyView()
        configureFilesToolbarView()
        configureGestures()
        configureDropFiles()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.updatePartnerName()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        defer { viewAppeared = true }
        inputBar.isUserInteractionEnabled = true
        chatMessagesCollectionView.fixedBottomOffset = nil
        
        if !viewAppeared {
            viewModel.presentKeyboardOnStartIfNeeded()
        }
        
        guard isMacOS, !viewAppeared else { return }
        focusInputBarWithoutAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inputBar.isUserInteractionEnabled = false
        inputBar.inputTextView.resignFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.preserveFiles()
        viewModel.preserveMessage(inputBar.text)
        viewModel.preserveReplayMessage()
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
        // TODO: refactor for architecture
        if let index = viewModel.needToAnimateCellIndex,
           indexPath.section == index {
            cell.isSelected = true
            cell.isSelected = false
            viewModel.needToAnimateCellIndex = nil
        }
        
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }
    
    override func scrollViewDidEndDecelerating(_: UIScrollView) {
        scrollDidStop()
    }
    
    override func scrollViewDidEndDragging(_: UIScrollView, willDecelerate: Bool) {
        guard !willDecelerate else { return }
        scrollDidStop()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        updateIsScrollPositionNearlyTheBottom()
        updateScrollDownButtonVisibility()
        
        if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating {
            updateDateHeaderIfNeeded()
        }
        
        guard
            viewAppeared,
            scrollView.contentOffset.y <= viewModel.minOffsetForStartLoadNewMessages
        else { return }
        
        viewModel.loadMoreMessagesIfNeeded()
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
            chatMessagesCollectionView.stopDecelerating()
            messagesCollectionView.isScrollEnabled = false
        }
        
        if state == .ended {
            messagesCollectionView.isScrollEnabled = true
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
    func scrollDidStop() {
        viewModel.startHideDateTimer()
    }
    
    func setupObservers() {
        NotificationCenter.default
            .notifications(named: UITextView.textDidChangeNotification, object: inputBar.inputTextView)
            .sink { @MainActor [weak self] _ in self?.inputTextUpdated() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: UIApplication.didBecomeActiveNotification)
            .sink { @MainActor [weak self] _ in
                guard let self = self else { return }
                let indexes = self.messagesCollectionView.indexPathsForVisibleItems
                self.viewModel.updatePreviewFor(indexes: indexes)
            }
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
                
        viewModel.presentKeyboard
            .sink { [weak self] in
                self?.messageInputBar.inputTextView.becomeFirstResponder()
            }
            .store(in: &subscriptions)
        
        viewModel.$isSendingAvailable
            .removeDuplicates()
            .sink(receiveValue: { [weak self] value in
                self?.inputBar.isEnabled = value
                if !value {
                    self?.navigationItem.rightBarButtonItem = nil
                } else {
                    self?.configureHeaderRightButton()
                }
            })
            .store(in: &subscriptions)
        
        viewModel.$fee
            .removeDuplicates()
            .assign(to: \.fee, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.didTapTransfer
            .sink { [weak self] in self?.didTapTransfer(id: $0) }
            .store(in: &subscriptions)
        
        viewModel.$partnerName
            .sink { [weak self] in self?.updatingIndicatorView.updateTitle(title: $0) }
            .store(in: &subscriptions)
        
        viewModel.$partnerImage
            .sink { [weak self] in self?.updatingIndicatorView.updateImage(image: $0) }
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
                    self?.viewModel.refreshDateHeadersIfNeeded()
                } else {
                    self?.updatingIndicatorView.stopAnimate()
                }
            }
            .store(in: &subscriptions)
        
        viewModel.$replyMessage
            .sink { [weak self] in self?.processSwipeMessage($0) }
            .store(in: &subscriptions)
        
        viewModel.$filesPicked
            .sink { [weak self] in self?.processFileToolbarView($0) }
            .store(in: &subscriptions)
        
        viewModel.$scrollToMessage
            .sink { [weak self] in
                guard let toId = $0,
                      let fromId = $1
                else { return }
                
                if self?.isScrollPositionNearlyTheBottom != true {
                    self?.viewModel.appendTempOffset(fromId, toId: toId)
                }
                self?.scrollToPosition(.messageId(toId), animated: true)
            }
            .store(in: &subscriptions)
        
        viewModel.$swipeState
            .sink { [weak self] in self?.swipeStateAction($0) }
            .store(in: &subscriptions)
        
        viewModel.$isNeedToAnimateScroll
            .sink { [weak self] in self?.animateScroll(isStarted: $0) }
            .store(in: &subscriptions)
        
        viewModel.$dateHeader
            .removeDuplicates()
            .sink { [weak self] in self?.dateHeaderLabel.text = $0 }
            .store(in: &subscriptions)
        
        viewModel.$dateHeaderHidden
            .removeDuplicates()
            .sink { [weak self] in self?.dateHeaderLabel.isHidden = $0 }
            .store(in: &subscriptions)
        
        viewModel.updateChatRead
            .sink { [weak self] in self?.checkIsChatWasRead() }
            .store(in: &subscriptions)
        
        viewModel.commitVibro
            .sink { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            .store(in: &subscriptions)
        
        viewModel.layoutIfNeeded
            .sink { [weak self] in self?.view.layoutIfNeeded() }
            .store(in: &subscriptions)
        
        viewModel.didTapPartnerQR
            .sink { [weak self] in self?.didTapPartenerQR(partner: $0) }
            .store(in: &subscriptions)
        
        viewModel.presentSendTokensVC
            .sink { [weak self] in
                guard let self = self else { return }
                
                sendTransaction(self, self.viewModel.replyMessage?.id)
                self.viewModel.clearReplyMessage()
                self.viewModel.clearPickedFiles()
            }
            .store(in: &subscriptions)
        
        viewModel.presentMediaPickerVC
            .sink { [weak self] in
                self?.presentMediaPicker()
            }
            .store(in: &subscriptions)
        
        viewModel.presentDocumentPickerVC
            .sink { [weak self] in
                self?.presentDocumentPicker()
            }
            .store(in: &subscriptions)
        
        viewModel.presentDocumentViewerVC
            .sink { [weak self] (files, index) in
                self?.presentDocumentViewer(files: files, selectedIndex: index)
            }
            .store(in: &subscriptions)
        
        viewModel.presentDropView
            .sink { [weak self]  in self?.presentDropView($0) }
            .store(in: &subscriptions)

        viewModel.didTapSelectText
            .sink { [weak self] text in
                self?.didTapSelectText(text: text)
            }
            .store(in: &subscriptions)
    }
}

// MARK: Configuration

private extension ChatViewController {
    func configureDropFiles() {
        chatDropView.alpha = .zero
        view.addSubview(chatDropView)
        chatDropView.snp.makeConstraints {
            $0.directionalEdges.equalTo(view.safeAreaLayoutGuide).inset(5)
        }
        
        view.addInteraction(UIDropInteraction(delegate: viewModel.dropInteractionService))
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
        navigationItem.titleView = updatingIndicatorView
        navigationItem.largeTitleDisplayMode = .never
        
        configureHeaderRightButton()
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(shortTapAction)
        )
        
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(longTapAction(_:))
        )
        
        navigationItem.titleView?.addGestureRecognizer(tapGesture)
        navigationItem.titleView?.addGestureRecognizer(longPressGesture)
        
        view.addSubview(dateHeaderLabel)
        dateHeaderLabel.backgroundColor = .adamant.chatSenderBackground
        dateHeaderLabel.textInsets = .init(top: 4, left: 7, bottom: 4, right: 7)
        dateHeaderLabel.layer.cornerRadius = 10
        dateHeaderLabel.clipsToBounds = true
        dateHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }
    }
    
    func configureHeaderRightButton() {
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
    
    func configureFilesToolbarView() {
        filesToolbarView.snp.makeConstraints { make in
            make.height.equalTo(filesToolbarViewHeight)
        }
        
        filesToolbarView.closeAction = { [weak self] in
            self?.viewModel.updateFiles(nil)
        }
        
        filesToolbarView.updatedDataAction = { [weak self] data in
            self?.viewModel.updateFiles(data)
        }
        
        filesToolbarView.openFileAction = { [weak self] data in
            self?.presentDocumentViewer(url: data.url)
        }
    }
    
    func configureGestures() {
        /// Replaces the delegate of the pan gesture recognizer used in the input bar control of MessageKit.
        /// This gesture controls the position of the input bar when the keyboard is open and the user swipes it to dismiss.
        /// Due to incorrect checks in MessageKit, we manually set the delegate and assign it to our custom chatKeyboardManager object.
        /// This ensures proper handling and control of the pan gesture for the input bar.
        if let gesture = messagesCollectionView.gestureRecognizers?[safe: 13] as? UIPanGestureRecognizer {
            gesture.delegate = chatKeyboardManager
            chatKeyboardManager.panGesture = gesture
        }
        
        /// Resolves the conflict between horizontal swipe gestures and vertical scrolling in the MessageKit's UICollectionView.
        /// The gestureRecognizerShouldBegin method checks the velocity of the pan gesture and allows it to begin only if the horizontal velocity is greater than the vertical velocity.
        /// This ensures smooth and uninterrupted vertical scrolling while still allowing horizontal swipe gestures to be recognized.
        let panGesture = UIPanGestureRecognizer()
        panGesture.delegate = self
        messagesCollectionView.addGestureRecognizer(panGesture)
        messagesCollectionView.clipsToBounds = false
    }

    func presentMediaPicker() {
        messageInputBar.inputTextView.resignFirstResponder()
        
        viewModel.mediaPickerDelegate.preSelectedFiles = viewModel.filesPicked ?? []
        
        let assetIds = viewModel.filesPicked?.compactMap { $0.assetId } ?? []

        var phPickerConfig = PHPickerConfiguration(photoLibrary: .shared())
        phPickerConfig.selectionLimit = FilesConstants.maxFilesCount
        phPickerConfig.filter = PHPickerFilter.any(of: [.images, .videos, .livePhotos])
        phPickerConfig.preselectedAssetIdentifiers = assetIds
        phPickerConfig.selection = .ordered
        
        let phPickerVC = PHPickerViewController(configuration: phPickerConfig)
        phPickerVC.delegate = viewModel.mediaPickerDelegate
        present(phPickerVC, animated: true)
    }
    
    func presentDocumentPicker() {
        messageInputBar.inputTextView.resignFirstResponder()
        
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.data, .content],
            asCopy: false
        )
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = viewModel.documentPickerDelegate
        present(documentPicker, animated: true)
    }
    
    func presentDocumentViewer(files: [FileResult], selectedIndex: Int) {
        viewModel.documentViewerService.openFile(
            files: files
        )
        
        let quickVC = QLPreviewController()
        quickVC.delegate = viewModel.documentViewerService
        quickVC.dataSource = viewModel.documentViewerService
        quickVC.modalPresentationStyle = .fullScreen
        quickVC.currentPreviewItemIndex = selectedIndex
        
        if let splitViewController = splitViewController {
            splitViewController.present(quickVC, animated: true)
        } else {
            present(quickVC, animated: true)
        }
    }
    
    func presentDocumentViewer(url: URL) {
        viewModel.documentViewerService.openFile(url: url)
        
        let quickVC = QLPreviewController()
        quickVC.delegate = viewModel.documentViewerService
        quickVC.dataSource = viewModel.documentViewerService
        quickVC.modalPresentationStyle = .fullScreen
        
        if let splitViewController = splitViewController {
            splitViewController.present(quickVC, animated: true)
        } else {
            present(quickVC, animated: true)
        }
    }
    
    func presentDropView(_ value: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.chatDropView.alpha = value ? 1.0 : .zero
        }
    }
}

// MARK: Tap on title view

private extension ChatViewController {
    @objc func shortTapAction() {
        viewModel.openPartnerQR()
    }
    
    @objc func longTapAction(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        viewModel.renamePartner()
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
    
    func updateDateHeaderIfNeeded() {
        guard viewAppeared else { return }
        
        let targetY: CGFloat = targetYOffset + view.safeAreaInsets.top
        let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
        
        for indexPath in visibleIndexPaths {
            guard let cell = messagesCollectionView.cellForItem(at: indexPath)
            else { continue }
            
            let cellRect = messagesCollectionView.convert(cell.frame, to: self.view)
            
            guard cellRect.minY <= targetY && cellRect.maxY >= targetY else {
                continue
            }
            
            viewModel.checkTopMessage(indexPath: indexPath)
            break
        }
    }
}

// MARK: Making entities

private extension ChatViewController {
    func makeScrollDownButton() -> ChatScrollDownButton {
        let button = ChatScrollDownButton()
        button.action = { [weak self] in
            guard let id = self?.viewModel.getTempOffset(visibleIndex: self?.messagesCollectionView.indexPathsForVisibleItems.last?.section)
            else {
                self?.viewModel.animateScrollIfNeeded(
                    to: self?.viewModel.messages.count ?? 0,
                    visibleIndex: self?.messagesCollectionView.indexPathsForVisibleItems.last?.section
                )
                
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
        collection.register(ChatTransactionCell.self)
        collection.register(ChatMessageCell.self)
        collection.register(ChatMessageReplyCell.self)
        collection.register(ChatMediaCell.self)
        collection.register(
            SpinnerCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )
        
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
        case let .messageId(id, scrollToBottomIfNotFound):
            var index = viewModel.messages.firstIndex(where: { $0.messageId == id})
            var needToAnimateCell = true
            
            if scrollToBottomIfNotFound,
               index == nil {
                index = viewModel.messages.count - 1
                needToAnimateCell = false
            }
            
            guard let index = index else { break }
            
            messagesCollectionView.scrollToItem(
                at: .init(item: .zero, section: index),
                at: [.centeredVertically, .centeredHorizontally],
                animated: animated
            )
            
            viewModel.needToAnimateCellIndex = needToAnimateCell
            ? index
            : nil
            
            guard animated else { break }
            
            viewModel.animateScrollIfNeeded(
                to: index,
                visibleIndex: messagesCollectionView.indexPathsForVisibleItems.last?.section
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
            if messageInputBar.topStackView.arrangedSubviews.isEmpty {
                UIView.transition(
                    with: messageInputBar.topStackView,
                    duration: 0.25,
                    options: [.transitionCrossDissolve],
                    animations: {
                        self.messageInputBar.topStackView.insertArrangedSubview(
                            self.replyView,
                            at: .zero
                        )
                    })
            } else {
                messageInputBar.topStackView.insertArrangedSubview(
                    replyView,
                    at: .zero
                )
            }
            
            if viewAppeared {
                messageInputBar.inputTextView.becomeFirstResponder()
            }
        }
        
        replyView.update(with: message)
    }
    
    func closeReplyView() {
        replyView.removeFromSuperview()
        messageInputBar.invalidateIntrinsicContentSize()
    }
    
    func processFileToolbarView(_ data: [FileResult]?) {
        guard let data = data, !data.isEmpty else {
            inputBar.isForcedSendEnabled = false
            closeFileToolbarView()
            return
        }
        
        inputBar.isForcedSendEnabled = true
        
        if !messageInputBar.topStackView.subviews.contains(filesToolbarView) {
            UIView.transition(
                with: messageInputBar.topStackView,
                duration: 0.25,
                options: [.transitionCrossDissolve],
                animations: {
                    self.messageInputBar.topStackView.insertArrangedSubview(
                        self.filesToolbarView,
                        at: self.messageInputBar.topStackView.arrangedSubviews.count
                    )
                })
            if viewAppeared {
                messageInputBar.inputTextView.becomeFirstResponder()
            }
        }
        
        filesToolbarView.update(data)
    }
    
    func closeFileToolbarView() {
        filesToolbarView.removeFromSuperview()
        messageInputBar.invalidateIntrinsicContentSize()
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
        let vc = screensFactory.makeAdmTransactionDetails(transaction: transaction)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func didTapPartenerQR(partner: CoreDataAccount) {
        let vc = screensFactory.makePartnerQR(partner: partner)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func didTapSelectText(text: String) {
        let vc = screensFactory.makeChatSelectTextView(text: text)
        present(vc, animated: true)
    }
    
    func didTapRichMessageTransaction(_ transaction: RichMessageTransaction) {
        guard
            let type = transaction.richType,
            let provider = walletServiceCompose.getWallet(by: type),
            let vc = screensFactory.makeDetailsVC(service: provider, transaction: transaction)
        else { return }
        
        switch transaction.transactionStatus {
        case .failed:
            guard transaction.getRichValue(for: RichContentKeys.transfer.hash) != nil
            else {
                viewModel.dialog.send(.alert(.adamant.sharedErrors.inconsistentTransaction))
                return
            }
            
            navigationController?.pushViewController(vc, animated: true)
        case .notInitiated, .pending, .success, .none, .inconsistent, .registered, .noNetwork, .noNetworkFinal:
            navigationController?.pushViewController(vc, animated: true)
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
        getMessageByIndexPath(indexPath)?.messageId
    }
    
    func getMessageByIndexPath(_ indexPath: IndexPath) -> MessageType? {
        messagesCollectionView.messagesDataSource?.messageForItem(
            at: indexPath,
            in: messagesCollectionView
        )
    }
    
    func animateScroll(isStarted: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.messagesCollectionView.alpha = isStarted ? 0.2 : 1.0
        }
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
        guard let admWalletService = admWalletService else { return }
        let vc = screensFactory.makeTransferVC(service: admWalletService)
        vc.recipientAddress = adm.address
        vc.recipientName = adm.name
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: Animate cell

extension ChatViewController {
    override func scrollViewDidEndScrollingAnimation(_: UIScrollView) {
        animateScroll(isStarted: false)
        
        guard let index = viewModel.needToAnimateCellIndex else { return }
        
        let isVisible = messagesCollectionView.indexPathsForVisibleItems.contains {
            $0.section == index
        }
        
        guard isVisible else { return }
        
        // TODO: refactor for architecture
        let cell = messagesCollectionView.cellForItem(at: .init(item: .zero, section: index))
        cell?.isSelected = true
        cell?.isSelected = false
        
        viewModel.needToAnimateCellIndex = nil
    }
}

private let scrollDownButtonInset: CGFloat = 20
private let messagePadding: CGFloat = 12
private let filesToolbarViewHeight: CGFloat = 140
private let targetYOffset: CGFloat = 20
