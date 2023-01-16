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
import SafariServices

final class ChatViewController: MessagesViewController {
    typealias SpinnerCell = MessageCellWrapper<SpinnerView>
    typealias TransactionCell = CollectionCellWrapper<ChatTransactionContainerView>
    typealias SendTransaction = (UIViewController & ComplexTransferViewControllerDelegate) -> Void
    
    private var subscriptions = Set<AnyCancellable>()
    private var storedObjects: [AnyObject]
    private var didScrollSender = ObservableSender<Void>()
    private var topMessageId: String?
    private var messagesLoaded = false
    
    private lazy var inputBar = ChatInputBar()
    private lazy var loadingView = LoadingView()
    
    private lazy var chatMessagesCollectionView = ChatMessagesCollectionView(
        didScroll: didScrollSender.eraseToAnyPublisher()
    )
    
    let viewModel: ChatViewModel
    
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
        storedObjects: [AnyObject],
        sendTransaction: @escaping SendTransaction
    ) {
        self.viewModel = viewModel
        self.storedObjects = storedObjects
        super.init(nibName: nil, bundle: nil)
        inputBar.onAttachmentButtonTap = { [weak self] in self.map { sendTransaction($0) } }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .adamant.backgroundColor
        maintainPositionOnInputBarHeightChanged = true
        configureMessagesCollectionView()
        configureLayout()
        setupObservers()
        viewModel.loadFirstMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatMessagesCollectionView.animationEnabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.preserveMessage(inputBar.text)
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
        didScrollSender.send()
    }
}

extension ChatViewController: ComplexTransferViewControllerDelegate {
    func complexTransferViewController(
        _: ComplexTransferViewController,
        didFinishWithTransfer: TransactionDetails?,
        detailsViewController: UIViewController?
    ) {
        DispatchQueue.onMainAsync { [weak self] in
            if didFinishWithTransfer != nil {
                self?.messagesCollectionView.scrollToLastItem()
            }
            
            self?.dismiss(animated: true)
            guard let detailsViewController = detailsViewController else { return }
            self?.navigationController?.pushViewController(detailsViewController, animated: true)
        }
    }
}

private extension ChatViewController {
    func setupObservers() {
        NotificationCenter
            .default
            .publisher(for: UITextView.textDidChangeNotification, object: inputBar.inputTextView)
            .sink { [weak self] _ in self?.inputTextUpdated() }
            .store(in: &subscriptions)
        
        viewModel.scrollDown
            .sink { [weak messagesCollectionView] _ in
                messagesCollectionView?.scrollToLastItem()
            }
            .store(in: &subscriptions)
        
        viewModel.messages
            .removeDuplicates()
            .combineLatest(viewModel.sender.removeDuplicates())
            .sink { [weak self] _ in self?.updateMessages() }
            .store(in: &subscriptions)
        
        viewModel.loadingStatus
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateLoadingViews() }
            .store(in: &subscriptions)
        
        viewModel.inputText
            .removeDuplicates()
            .assign(to: \.text, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.showFreeTokensAlert
            .sink { [weak self] in self?.showFreeTokenAlert() }
            .store(in: &subscriptions)
        
        viewModel.isSendingAvailable
            .removeDuplicates()
            .assign(to: \.isEnabled, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.fee
            .removeDuplicates()
            .assign(to: \.fee, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.didTapTransfer
            .sink { [weak self] in self?.didTapTransfer(id: $0) }
            .store(in: &subscriptions)
    }
    
    func setupMessageToShowObserver() {
        viewModel.messageIdToShow
            .sink { [weak self] in $0.map { self?.showMessage(id: $0) } }
            .store(in: &subscriptions)
    }
    
    func configureMessagesCollectionView() {
        messagesCollectionView.backgroundColor = .adamant.backgroundColor
        messagesCollectionView.register(TransactionCell.self)
        
        messagesCollectionView.register(
            SpinnerCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )
    }
    
    func configureLayout() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    func updateMessages() {
        if topMessageId == viewModel.messages.value.first?.messageId {
            messagesCollectionView.reloadData()
        } else {
            chatMessagesCollectionView.reloadDataWithFixedBottom()
        }
        
        topMessageId = viewModel.messages.value.first?.messageId
        
        guard !messagesLoaded, topMessageId != nil else { return }
        setupMessageToShowObserver()
        messagesLoaded = true
    }
    
    func updateLoadingViews() {
        updateFullscreenLoadingView()
        updateTopLoadingView()
    }
    
    func updateFullscreenLoadingView() {
        let isLoading = viewModel.loadingStatus.value == .fullscreen
        loadingView.isHidden = !isLoading
        
        if isLoading {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }
    
    func updateTopLoadingView() {
        guard messagesCollectionView.numberOfSections > .zero else { return }
        
        UIView.performWithoutAnimation {
            switch viewModel.loadingStatus.value {
            case .onTop:
                messagesCollectionView.reloadSections(.init(integer: .zero))
            case .fullscreen, .none:
                chatMessagesCollectionView.reloadSectionsWithFixedBottom(.init(integer: .zero))
            }
        }
    }
    
    func showFreeTokenAlert() {
        let alert = UIAlertController(
            title: "",
            message: String.adamantLocalized.chat.freeTokensMessage,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(
            title: String.adamantLocalized.alert.cancel,
            style: .default,
            handler: nil
        )
        
        alert.addAction(makeFreeTokensAlertAction())
        alert.addAction(cancelAction)
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
    
    func makeFreeTokensAlertAction() -> UIAlertAction {
        .init(
            title: String.adamantLocalized.chat.freeTokens,
            style: .default
        ) { [weak self] _ in
            guard let self = self, let url = self.viewModel.freeTokensURL else { return }
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            self.present(safari, animated: true, completion: nil)
        }
    }
    
    func showMessage(id: String) {
        guard let index = viewModel.messages.value.firstIndex(where: { $0.messageId == id})
        else { return }
        
        messagesCollectionView.scrollToItem(
            at: .init(item: .zero, section: index),
            at: [.centeredVertically, .centeredHorizontally],
            animated: false
        )
    }
    
    func inputTextUpdated() {
        viewModel.inputText.value = inputBar.text
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
            let provider = viewModel.richMessageProviders[AdmWalletService.richMessageType]
                as? AdmWalletService
        else { return }
        
        provider.richMessageTapped(for: transaction, in: self)
    }
    
    func didTapRichMessageTransaction(_ transaction: RichMessageTransaction) {
        guard
            let type = transaction.richType,
            let provider = viewModel.richMessageProviders[type]
        else { return }
        
        switch transaction.transactionStatus {
        case .dublicate:
            viewModel.showDublicatedTransactionAlert()
        case .failed:
            viewModel.showFailedTransactionAlert()
        case .notInitiated, .pending, .success, .updating, .warning, .none:
            provider.richMessageTapped(for: transaction, in: self)
        }
    }
}
