//
//  ChatViewController.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine
import CommonKit
import FilesPickerKit
import FilesStorageKit
import InputBarAccessoryView
import MessageKit
import PhotosUI
import QuickLook
import SnapKit
import UIKit

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
    private let chatSwipeManager: ChatSwipeManager

    let viewModel: ChatViewModel

    // MARK: Properties

    private var subscriptions = Set<AnyCancellable>()
    private var bottomMessageId: String?
    private var state = ChatViewControllerState()
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?
    
    deinit {
        if let backgroundObserver = backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
        if let foregroundObserver = foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
        }
    }

    private lazy var inputBar = ChatInputBar()
    private lazy var loadingView = LoadingView()
    private lazy var scrollDownButton = makeScrollDownButton()
    private lazy var scrollToUnreadReactButton = makeScrollToUnreadReactButton()
    private lazy var chatMessagesCollectionView = makeChatMessagesCollectionView()
    private lazy var replyView = ReplyView()
    private lazy var filesToolbarView = FilesToolbarView()
    private lazy var chatDropView = ChatDropView()
    private lazy var dateHeaderLabel = EdgeInsetLabel(
        font: .adamantPrimary(ofSize: 13),
        textColor: .adamant.textColor,
        numberOfLines: 1
    )
    private var updateDownButtonPublisher = ObservableSender<Void>()

    private var keyboardHeight: CGFloat = 0
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
        chatSwipeManager: ChatSwipeManager,
        sendTransaction: @escaping SendTransaction
    ) {
        self.viewModel = viewModel
        self.storedObjects = storedObjects
        self.walletServiceCompose = walletServiceCompose
        self.admWalletService = admWalletService
        self.screensFactory = screensFactory
        self.sendTransaction = sendTransaction
        self.chatSwipeManager = chatSwipeManager
        super.init(nibName: nil, bundle: nil)

        inputBar.onAttachmentButtonTap = { [weak self] in
            self?.viewModel.presentActionMenu()
        }

        inputBar.onImagePasted = { [weak self] image in
            self?.viewModel.handlePastedImage(image)
        }

        viewModel.indexPathsForVisibleItems = { [weak self] in
            self?.messagesCollectionView.indexPathsForVisibleItems ?? .init()
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
        chatSwipeManager.configure(chatView: view)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateIsScrollPositionNearlyTheBottom()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        chatMessagesCollectionView.setFullBottomInset(
            view.bounds.height - inputContainerView.frame.minY
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController?.delegate !== self {
            navigationController?.delegate = self
        }
        viewModel.updatePartnerName()
        updateDownButtonPublisher.send()

        // Needs to check the current state of the chats update to present or hide spinner on appear instantly
        viewModel.checkUpdateState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        defer {
            state.isFirstTimeViewAppeared = true
            state.isViewDissappeared = false
            updateUnreadMessages()
        }
        inputBar.isUserInteractionEnabled = true
        chatMessagesCollectionView.fixedBottomOffset = nil
        if !state.isFirstTimeViewAppeared {
            viewModel.presentKeyboardOnStartIfNeeded()
        }

        guard isMacOS, !state.isFirstTimeViewAppeared else { return }
        focusInputBarWithoutAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateUnreadMessages()
        inputBar.isUserInteractionEnabled = false
        inputBar.inputTextView.resignFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.preserveMessage(inputBar.text)
        
        var bottomOffset = chatMessagesCollectionView.bottomOffset
        var collectionHeight: CGFloat = messagesCollectionView.contentSize.height
        if viewModel.separatorState.separatorIndex != nil {
            collectionHeight -= separatorHeight
            bottomOffset -= separatorHeight
        }
        
        viewModel.saveChatOffset(
            state.isScrollPositionNearlyTheBottom
                ? nil
            : bottomOffset, collectionHeight: collectionHeight
        )
            
        state.isViewDissappeared = true
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        canPerformAction action: Selector,
        forItemAt indexPath: IndexPath,
        withSender sender: Any?
    ) -> Bool {
        return false
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        shouldShowMenuForItemAt indexPath: IndexPath
    ) -> Bool {
        return false
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
        if state.isInitialMessagesWereUpdated {
            updateUnreadMessages()
        }
        updateIsScrollPositionNearlyTheBottom()
        if let ids = viewModel.unreadMessagesIds,
           ids.count > 0 {
            updateDownButtonPublisher.send()
        } else {
            updateScrollDownButtonVisibility()
        }

        if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating {
            updateDateHeaderIfNeeded()
        }
        guard
            state.isFirstTimeViewAppeared,
            scrollView.contentOffset.y <= viewModel.minOffsetForStartLoadNewMessages
        else { return }

        viewModel.loadMoreMessagesIfNeeded()
    }
}

// https://trello.com/c/m0k5mrQR/868-bug-after-some-time-in-background-messages-menu-stop-working-on-macos-crash
extension ChatViewController {
    fileprivate func setupBackgroundObservers() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterBackground()
        }
        
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }
    }
    
    fileprivate func handleAppWillEnterBackground() {
        inputBar.inputTextView.resignFirstResponder()
    }
    
    fileprivate func handleAppWillEnterForeground() {
        guard isMacOS else { return }
        
        inputBar.isUserInteractionEnabled = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.refreshContextMenuInteractions()
        }
    }
    
    fileprivate func refreshContextMenuInteractions() {
        let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
        
        guard !visibleIndexPaths.isEmpty else { return }
        
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.reloadItems(at: visibleIndexPaths)
        }, completion: nil)
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

extension ChatViewController {
    fileprivate func scrollDidStop() {
        viewModel.startHideDateTimer()
    }

    fileprivate func setupObservers() {
        NotificationCenter.default
            .notifications(named: UITextView.textDidChangeNotification, object: inputBar.inputTextView)
            .sink { @MainActor [weak self] _ in self?.inputTextUpdated() }
            .store(in: &subscriptions)

        NotificationCenter.default
            .notifications(named: UIApplication.didBecomeActiveNotification)
            .sink { @MainActor [weak self] _ in
                guard let self = self else { return }
                self.state.isAppActive = true
                self.updateUnreadMessages()
                let indexes = self.messagesCollectionView.indexPathsForVisibleItems
                self.viewModel.updatePreviewFor(indexes: indexes)
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.state.isAppActive = false
            }
            .store(in: &subscriptions)
        
        if !isMacOS {
            NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)
                .sink { [weak self] notification in
                    guard let self,
                          let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                          let window = self.view.window else { return }
                    
                    let convertedFrame = self.view.convert(frame, from: window)
                    keyboardHeight = max(self.view.bounds.maxY - convertedFrame.minY - hiddenScrollViewPartHeight / 2, 0)
                }
                .store(in: &subscriptions)
        }

        viewModel.didTapAdmNodesList
            .sink { [weak self] in
                self?.didTapReviewAdmNodes()
            }
            .store(in: &subscriptions)

        viewModel.didTapShowTimeSettings
            .sink { [weak self] in
                self?.didTapShowTimeSettings()
            }
            .store(in: &subscriptions)

        viewModel.$messages
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateMessages()
            }
            .store(in: &subscriptions)

        viewModel.messagesUpdated
            .sink { [weak self] _ in
                self?.updateMessagesPosition()
                self?.state.isInitialMessagesWereUpdated = true
                self?.updateUnreadMessages()
            }
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

        viewModel.$scrollToId
            .sink { [weak self] in
                guard let id = $0
                else { return }
                self?.scrollToPosition(.messageId(id), animated: true)
                self?.state.shouldScrollToNewMessages = false
                self?.viewModel.messageIdToShow = nil
            }
            .store(in: &subscriptions)

        viewModel.enableScroll
            .sink { [weak self] in self?.enableScroll($0) }
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
            .sink { [weak self] in self?.presentDropView($0) }
            .store(in: &subscriptions)

        viewModel.didTapSelectText
            .sink { [weak self] text in
                self?.didTapSelectText(text: text)
            }
            .store(in: &subscriptions)

        viewModel.$unreadMessagesIds
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateDownButtonPublisher.send()
            }
            .store(in: &subscriptions)

        viewModel.$messagesWithUnredReactionsIds
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateScrollToUnreadButtonVisibility()
            }
            .store(in: &subscriptions)

        viewModel.showBuyAndSell
            .sink { [weak self] in
                self?.presentBuyAndSell()
            }
            .store(in: &subscriptions)
        
        viewModel.separatorState.$separatorIndex
            .removeDuplicates()
            .sink { [weak self] index in
                guard let self = self,
                      let index,
                      index < self.messagesCollectionView.numberOfSections else { return }
                self.adjustScrollIfHeightIncreased()
                UIView.performWithoutAnimation {
                    self.messagesCollectionView.performBatchUpdates {
                        self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    }
                }
            }
            .store(in: &subscriptions)
        
        updateDownButtonPublisher
            .debounce(for: .milliseconds(delayForDownButtonUpdate), scheduler: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self else { return }
                self.updateScrollDownButtonVisibility()
            }
            .store(in: &subscriptions)
    }
}

// MARK: Configuration

extension ChatViewController {
    fileprivate func configureDropFiles() {
        chatDropView.alpha = .zero
        view.addSubview(chatDropView)
        chatDropView.snp.makeConstraints {
            $0.directionalEdges.equalTo(view.safeAreaLayoutGuide).inset(5)
        }

        view.addInteraction(UIDropInteraction(delegate: viewModel.dropInteractionService))
    }

    fileprivate func configureLayout() {
        view.addSubview(scrollDownButton)
        view.addSubview(scrollToUnreadReactButton)
        scrollDownButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(scrollDownButtonInset)
            $0.bottom.equalTo(inputBar.snp.top).offset(-scrollDownButtonInset)
            $0.size.equalTo(scrollButtonHeight)
        }
        scrollToUnreadReactButton.snp.makeConstraints {
            $0.centerX.equalTo(scrollDownButton.snp.centerX)
            self.state.scrollToUnreadBottomConstraint = $0.bottom.equalTo(scrollDownButton.snp.bottom).constraint
            $0.size.equalTo(scrollButtonHeight + 6)
        }

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }

    fileprivate func updateScrollToUnreadButtonPosition() {
        let offset = (scrollDownButton.alpha == 0) ? 0 : -(scrollToUnreadInset + scrollButtonHeight)
        state.scrollToUnreadBottomConstraint?.update(offset: offset)
        if state.isMessagesLoaded {
            self.view.layoutIfNeeded()
        }
    }

    fileprivate func updateUnreadMessages() {
        guard state.canReadChat else { return }
        guard let unreadIndexes = viewModel.unreadMesaggesIndexes, !unreadIndexes.isEmpty else { return }

        // Keep the bottom excluded zone capped by real insets; on compact screens (iPhone SE 3rd for example)
        // a fixed value can mark visible bottom messages as unread.
        let bottomReadableInset = min(
            hiddenScrollViewPartHeight,
            chatMessagesCollectionView.fullInsets.bottom
        )
        let adjustedVisibleHeight = max(
            messagesCollectionView.bounds.height - hiddenScrollViewPartHeight - bottomReadableInset - keyboardHeight,
            .zero
        )
        let adjustedVisibleRect = CGRect(
            x: messagesCollectionView.contentOffset.x,
            y: messagesCollectionView.contentOffset.y + hiddenScrollViewPartHeight,
            width: messagesCollectionView.bounds.width,
            height: adjustedVisibleHeight
        )

        let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems

        for indexPath in visibleIndexPaths where unreadIndexes.contains(indexPath.section) {
            guard let attributes = messagesCollectionView.layoutAttributesForItem(at: indexPath) else { continue }
            let cellFrame = attributes.frame

            let bottomPoint = CGPoint(x: cellFrame.midX, y: cellFrame.maxY)
            let isBottomVisible = adjustedVisibleRect.contains(bottomPoint)

            if isBottomVisible {
                viewModel.markMessageAsRead(index: indexPath.section)
            }
        }
    }

    fileprivate func configureHeader() {
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

    fileprivate func configureHeaderRightButton() {
        navigationItem.rightBarButtonItem = .init(
            title: "•••",
            style: .plain,
            target: self,
            action: #selector(showMenu)
        )
    }

    fileprivate func configureReplyView() {
        replyView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        replyView.closeAction = { [weak self] in
            self?.viewModel.replyMessage = nil
        }
    }

    fileprivate func configureFilesToolbarView() {
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
            self?.presentDocumentViewer(file: data)
        }
    }

    fileprivate func configureGestures() {
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

    fileprivate func presentMediaPicker() {
        guard !isMacOS else { return presentDocumentPicker() }
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
        phPickerVC.view.tintColor = .systemBlue
        present(phPickerVC, animated: true)
    }

    fileprivate func presentDocumentPicker() {
        messageInputBar.inputTextView.resignFirstResponder()

        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.data, .content],
            asCopy: false
        )
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = viewModel.documentPickerDelegate
        present(documentPicker, animated: true)
    }

    fileprivate func presentDocumentViewer(files: [FileResult], selectedIndex: Int) {
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

    fileprivate func presentDocumentViewer(file: FileResult) {
        viewModel.documentViewerService.openFile(files: [file])

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

    fileprivate func presentDropView(_ value: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.chatDropView.alpha = value ? 1.0 : .zero
        }
    }
    fileprivate func presentBuyAndSell() {
        let buyAndSellVC = screensFactory.makeBuyAndSell()
        navigationController?.pushViewController(buyAndSellVC, animated: true)
    }
}

// MARK: Tap on title view

extension ChatViewController {
    @objc fileprivate func shortTapAction() {
        viewModel.openPartnerQR()
    }

    @objc fileprivate func longTapAction(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        viewModel.renamePartner()
    }
}

// MARK: Content updating

extension ChatViewController {
    fileprivate func updateIsScrollPositionNearlyTheBottom() {
        let isNearBottom = chatMessagesCollectionView.bottomOffset < 150
        state.isScrollPositionNearlyTheBottom = isNearBottom
        viewModel.separatorState.isScrollPositionNearlyTheBottom = isNearBottom
    }

    fileprivate func updateMessages() {
        chatMessagesCollectionView.reloadData(newIds: viewModel.messages.map { $0.id },
                                              isOnBottom: state.isScrollPositionNearlyTheBottom)

        scrollDownOnNewMessageIfNeeded(previousBottomMessageId: bottomMessageId)
        bottomMessageId = viewModel.messages.last?.messageId

        if !state.isMessagesLoaded {
            if let position = viewModel.startPosition {
                scrollToPosition(.offset(yOffset: position.offset))
                state.oldCollectionViewHeight = position.oldCollectionHeight
                state.shouldScrollToNewMessages = false
            }
        }
    }

    fileprivate func updateMessagesPosition() {
        guard !state.isMessagesLoaded, !viewModel.messages.isEmpty else { return }
        state.isMessagesLoaded = true
        if state.shouldScrollToNewMessages {
            if let unreadMessage = viewModel.unreadMessagesIds?.first {
                state.isAutoScrolling = true
                viewModel.animationType = MessageAnimationType.none
                let isFirstMessagesInChat = viewModel.unreadMessagesIds?.count == viewModel.messages.count
                scrollToPosition(.messageId(unreadMessage), setExtraOffset: !isFirstMessagesInChat, scrollAt: .top)
            }
        }
    }

    fileprivate func updateFullscreenLoadingView() {
        loadingView.isHidden = !viewModel.fullscreenLoading

        if viewModel.fullscreenLoading {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }

    fileprivate func updateScrollDownButtonVisibility() {
        let topCount = viewModel.unreadMessagesIds?.count ?? 0
        self.scrollDownButton.updateCounter(topCount)

        let shouldShowButton = (topCount > 0) || !state.isScrollPositionNearlyTheBottom
        guard state.isScrollDownButtonHidden != !shouldShowButton else { return }

        state.isScrollDownButtonHidden = !shouldShowButton
        let buttonUpdate = {
            self.scrollDownButton.alpha = shouldShowButton ? 1 : 0
            self.updateScrollToUnreadButtonPosition()
        }

        if state.isAnimationAllowed {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                buttonUpdate()
            }
        } else {
            buttonUpdate()
        }
    }

    fileprivate func updateScrollToUnreadButtonVisibility() {
        let count = viewModel.messagesWithUnredReactionsIds?.count ?? 0
        scrollToUnreadReactButton.updateCounter(count)

        guard (state.previousUnreadCount == 0 && count > 0) || (state.previousUnreadCount > 0 && count == 0) else {
            state.previousUnreadCount = count
            return
        }
        state.previousUnreadCount = count
        let updateAlpha = { self.scrollToUnreadReactButton.alpha = (count == 0) ? 0 : 1 }
        if state.isAnimationAllowed {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: updateAlpha)
        } else {
            updateAlpha()
        }
    }

    fileprivate func updateDateHeaderIfNeeded() {
        guard state.isFirstTimeViewAppeared else { return }

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
    
    fileprivate func markMessagesFromCurrentToBottomAsRead() {
        guard let unreadIndexes = viewModel.unreadMesaggesIndexes, !unreadIndexes.isEmpty else { return }

        let visibleSections = messagesCollectionView.indexPathsForVisibleItems.map { $0.section }
        guard let minSection = visibleSections.min() else { return }

        let totalSections = messagesCollectionView.numberOfSections
        guard totalSections > 0 else { return }

        for section in minSection..<totalSections {
            if unreadIndexes.contains(section) {
                viewModel.markMessageAsRead(index: section)
            }
        }
    }
}

// MARK: Making entities

extension ChatViewController {
    fileprivate func makeScrollDownButton() -> ChatScrollButton {
        let button = ChatScrollButton(position: .down)
        button.action = { [weak self] in
            guard let self else { return }
            scrollButtonAction()
        }
        button.alpha = 0
        return button
    }

    fileprivate func makeScrollToUnreadReactButton() -> ChatScrollButton {
        let button = ChatScrollButton(position: .reaction)
        button.action = { [weak self] in
            guard let self,
                let unreadId = self.viewModel.messagesWithUnredReactionsIds?.last
            else { return }
            state.isAnimatingCellHighlight = false
            viewModel.animationType = .reaction
            viewModel.scroll(to: unreadId)
        }
        button.alpha = 0
        return button
    }

    fileprivate func makeChatMessagesCollectionView() -> ChatMessagesCollectionView {
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
        collection.register(
            NewMessagesCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter
        )
        collection.enableKeyboardDismissOnTap(targetView: collection)
        
        return collection
    }
    
    fileprivate func scrollButtonAction() {
        if viewModel.shouldScrollToBottom {
            scrollToBottom()
            return
        }

        guard let firstUnreadId = viewModel.unreadMessagesIds?.first,
              let unreadIndex = viewModel.messages.firstIndex(where: { $0.messageId == firstUnreadId }) else {
            scrollToBottom()
            return
        }

        let visibleBounds = messagesCollectionView.bounds
        let restrictedVisibleRect = visibleBounds.insetBy(dx: 0, dy: 100)

        let visibleSections: Set<Int> = Set(
            messagesCollectionView.indexPathsForVisibleItems.compactMap {
                guard let frame = messagesCollectionView.layoutAttributesForItem(at: $0)?.frame,
                      restrictedVisibleRect.intersects(frame) else { return nil }
                return $0.section
            }
        )

        if visibleSections.contains(unreadIndex) {
            scrollToBottom()
            return
        }

        if let separatorIndex = viewModel.separatorState.separatorIndex,
           unreadIndex == separatorIndex + 1 {
            viewModel.animationType = .none
            scrollToPosition(.messageId(firstUnreadId), animated: false, setExtraOffset: true, scrollAt: .top)
            viewModel.shouldScrollToBottom = true
            return
        }

        viewModel.animationType = .none
        scrollToPosition(.messageId(firstUnreadId), animated: true, scrollAt: .top)
        viewModel.shouldScrollToBottom = true
    }
    
    fileprivate func scrollToBottom() {
        state.isScrollingToBottom = true
        markMessagesFromCurrentToBottomAsRead()
        messagesCollectionView.scrollToBottom(animated: true)
    }
}

// MARK: Other

extension ChatViewController {
    fileprivate func focusInputBarWithoutAnimation() {
        // "becomeFirstResponder()" causes content animation on start without this fix
        Task {
            try await Task.sleep(interval: .zero)
            messageInputBar.inputTextView.becomeFirstResponder()
        }
    }

    fileprivate func enableScroll(_ isEnabled: Bool) {
        if isEnabled {
            chatMessagesCollectionView.isScrollEnabled = true
        } else {
            chatMessagesCollectionView.stopDecelerating()
            chatMessagesCollectionView.isScrollEnabled = false
        }
    }

    fileprivate func dismissTransferViewController(
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

    @MainActor
    fileprivate func scrollToPosition(_ position: ChatStartPosition,
                                      animated: Bool = false,
                                      setExtraOffset: Bool = false,
                                      scrollAt: UICollectionView.ScrollPosition = .centeredVertically) {
        chatMessagesCollectionView.fixedBottomOffset = nil
        switch position {
        case let .offset(yOffset):
            state.isAutoScrolling = true
            
            chatMessagesCollectionView.setBottomOffset(yOffset, safely: state.isFirstTimeViewAppeared)
            state.isAutoScrolling = false
            guard !state.isFirstTimeViewAppeared else { return }
            chatMessagesCollectionView.fixedBottomOffset = chatMessagesCollectionView.bottomOffset
        case let .messageId(id, scrollToBottomIfNotFound):
            var index = viewModel.messages.firstIndex(where: { $0.messageId == id })
            var needToAnimateCell = true

            if scrollToBottomIfNotFound,
                index == nil
            {
                index = viewModel.messages.count - 1
                needToAnimateCell = false
            }

            guard let index = index else { break }

            state.isAutoScrolling = true
            messagesCollectionView.scrollToItem(
                at: .init(item: .zero, section: index),
                at: scrollAt,
                animated: animated
            )
            
            if setExtraOffset && !animated {
                if checkIfNeedExtraOffsetForUnreadMessages() {
                    setExtraOffsetForNewMessages()
                }
                state.isAutoScrolling = false
                updateUnreadMessages()
            }
            
            if viewModel.animationType != MessageAnimationType.none {
                viewModel.cellIdForAnimation = needToAnimateCell ? id : nil
            }
            
            let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
            let indexPath = IndexPath(item: 0, section: index)

            //if we will not trigger didEndScrolling
            if visibleIndexPaths.contains(indexPath) {
                state.isAutoScrolling = false

                if viewModel.animationType != MessageAnimationType.none {
                    animateCell(at: indexPath)
                }
            }

            guard animated else { break }

            viewModel.animateScrollIfNeeded(
                to: index,
                visibleIndex: messagesCollectionView.indexPathsForVisibleItems.last?.section
            )
        }
    }

    fileprivate func setExtraOffsetForNewMessages() {
        //extra scroll to 120 to see newMessage line and 2 strings from previus message
        let newOffsetY = max(
            messagesCollectionView.contentOffset.y - 120,
            0
        )
        let newOffset = CGPoint(x: messagesCollectionView.contentOffset.x, y: newOffsetY)

        messagesCollectionView.setContentOffset(newOffset, animated: false)
    }

    fileprivate func checkIfNeedExtraOffsetForUnreadMessages() -> Bool {
        guard let unreadCount = viewModel.unredMessageCount() else { return false }

        let totalSections = messagesCollectionView.numberOfSections
        let visibleHeight = messagesCollectionView.bounds.height
        var totalUnreadHeight: CGFloat = 0

        for i in 0..<unreadCount {
            let sectionIndex = totalSections - 1 - i
            let indexPath = IndexPath(item: 0, section: sectionIndex)

            guard let attributes = messagesCollectionView.layoutAttributesForItem(at: indexPath) else {
                continue
            }

            totalUnreadHeight += attributes.frame.height

            if totalUnreadHeight + 120 > visibleHeight {
                return true
            }
        }
        return false
    }

    fileprivate func scrollDownOnNewMessageIfNeeded(previousBottomMessageId: String?) {
        let messages = viewModel.messages

        guard
            let previousBottomMessageId = previousBottomMessageId,
            let index = messages.firstIndex(where: { $0.id == previousBottomMessageId }),
            index < messages.count - 1,
            state.isScrollPositionNearlyTheBottom
                || messages.last?.sender.senderId == viewModel.sender.senderId
                    && messages.last?.status == .pending
        else { return }

        messagesCollectionView.scrollToBottom(animated: true)
    }

    @objc fileprivate func showMenu(_ sender: UIBarButtonItem) {
        viewModel.dialog.send(.menu(sender: sender))
    }

    fileprivate func inputTextUpdated() {
        viewModel.inputText = inputBar.text
    }

    fileprivate func processSwipeMessage(_ message: MessageModel?) {
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
                    }
                )
            } else {
                messageInputBar.topStackView.insertArrangedSubview(
                    replyView,
                    at: .zero
                )
            }

            if state.isFirstTimeViewAppeared {
                messageInputBar.inputTextView.becomeFirstResponder()
            }
        }

        replyView.update(with: message)
    }

    fileprivate func closeReplyView() {
        replyView.removeFromSuperview()
        messageInputBar.invalidateIntrinsicContentSize()
    }

    fileprivate func processFileToolbarView(_ data: [FileResult]?) {
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
                }
            )
            if state.isFirstTimeViewAppeared {
                messageInputBar.inputTextView.becomeFirstResponder()
            }
        }

        filesToolbarView.update(data)
    }

    fileprivate func closeFileToolbarView() {
        filesToolbarView.removeFromSuperview()
        messageInputBar.invalidateIntrinsicContentSize()
    }

    fileprivate func didTapTransfer(id: String) {
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

    fileprivate func didTapReviewAdmNodes() {
        let vc = screensFactory.makeNodesList()
        navigationController?.pushViewController(vc, animated: true)
    }

    fileprivate func didTapShowTimeSettings() {
        let settingsURL = isMacOS ? "x-apple.systempreferences:com.apple.preference.datetime" : "App-prefs:root=General&path=DATE_AND_TIME"
        if let appSettings = URL(string: settingsURL),
            UIApplication.shared.canOpenURL(appSettings)
        {
            UIApplication.shared.open(appSettings)
        }
    }

    fileprivate func didTapTransferTransaction(_ transaction: TransferTransaction) {
        let vc = screensFactory.makeAdmTransactionDetails(transaction: transaction)
        navigationController?.pushViewController(vc, animated: true)
    }

    fileprivate func didTapPartenerQR(partner: CoreDataAccount) {
        let vc = screensFactory.makePartnerQR(partner: partner)
        navigationController?.pushViewController(vc, animated: true)
    }

    fileprivate func didTapSelectText(text: String) {
        let vc = screensFactory.makeChatSelectTextView(text: text)
        present(vc, animated: true)
    }

    fileprivate func didTapRichMessageTransaction(_ transaction: RichMessageTransaction) {
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
        case .notInitiated, .pending, .success, .none, .inconsistent, .registered:
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc fileprivate func onEnterClick() {
        if messageInputBar.inputTextView.isFirstResponder {
            messageInputBar.didSelectSendButton()
        } else {
            messageInputBar.inputTextView.becomeFirstResponder()
        }
    }

    fileprivate func getMessageIdByIndexPath(_ indexPath: IndexPath) -> String? {
        getMessageByIndexPath(indexPath)?.messageId
    }

    fileprivate func getMessageByIndexPath(_ indexPath: IndexPath) -> MessageType? {
        messagesCollectionView.messagesDataSource?.messageForItem(
            at: indexPath,
            in: messagesCollectionView
        )
    }

    fileprivate func animateScroll(isStarted: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.messagesCollectionView.alpha = isStarted ? 0.2 : 1.0
        }
    }

    // TODO: Use coordinator

    fileprivate func close() {
        let navVC =
            tabBarController?
            .selectedViewController?
            .children
            .first as? UINavigationController

        if let navVC = navVC {
            navVC.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    fileprivate func adjustScrollIfHeightIncreased() {
        guard let oldHeight = state.oldCollectionViewHeight,
              let offset = viewModel.startPosition?.offset,
              viewModel.separatorState.separatorId != nil
        else { return }
        
        var newHeight = messagesCollectionView.contentSize.height
        if isMacOS {
            newHeight -= separatorHeight
        }
        let heightDifference = newHeight - oldHeight
        
        scrollToPosition(.offset(yOffset: offset + separatorHeight + heightDifference))
        state.oldCollectionViewHeight = nil
    }
}

// MARK: Markdown

extension ChatViewController {
    fileprivate func didTapAdmChat(with chatroom: Chatroom, message: String?) {
        var chatlistVC: ChatListViewController?

        if let nav = splitViewController?.viewControllers.first as? UINavigationController,
            let vc = nav.viewControllers.first as? ChatListViewController
        {
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

    fileprivate func didTapAdmSend(to adm: AdamantAddress) {
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
        state.isAutoScrolling = false
        state.isScrollingToBottom = false
        updateUnreadMessages()
        
        guard !state.isAnimatingCellHighlight else { return }
        guard let messageId = viewModel.cellIdForAnimation,
              let index = viewModel.messages.firstIndex(where: { $0.messageId == messageId }) else {
            return
        }
        
        let indexPath = IndexPath(item: 0, section: index)
        animateCell(at: indexPath)
    }
    
    private func animateCell(at indexPath: IndexPath) {
        state.isAnimatingCellHighlight = true
        
        //0.2 sec delay that all methods that can interrupt the animation have time to execute
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            guard self.messagesCollectionView.indexPathsForVisibleItems.contains(indexPath),
                  let cell = self.messagesCollectionView.cellForItem(at: indexPath) as? ChatCellProtocol else {
                self.state.isAnimatingCellHighlight = false
                return
            }
            switch viewModel.animationType {
            case .message:
                cell.animateMessageHighlight()
                viewModel.shortVibro()
            case .reaction:
                cell.animateReactionHighlight()
                viewModel.shortVibro()
            case .none:
                break
            }
            self.viewModel.cellIdForAnimation = nil
            self.state.isAnimatingCellHighlight = false
        }
    }
}

private let scrollToUnreadInset: CGFloat = 10
private let scrollDownButtonInset: CGFloat = 20
private let messagePadding: CGFloat = 12
private let filesToolbarViewHeight: CGFloat = 140
private let targetYOffset: CGFloat = 20
private let scrollButtonHeight: CGFloat = 30
private let separatorHeight: CGFloat = 25
//not a real height just for reading messages
private var hiddenScrollViewPartHeight: CGFloat {
    if isMacOS {
        return 93
    } else {
        return 85
    }
}
//this deley is to give a short time to read new message and dont show down button with unread count for milliseconds
private let delayForDownButtonUpdate = 200
