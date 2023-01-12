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
    
    private let delegates: Delegates
    private var subscriptions = Set<AnyCancellable>()
    private var didScrollSender = ObservableSender<Void>()
    
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
    
    init(viewModel: ChatViewModel, delegates: Delegates) {
        self.viewModel = viewModel
        self.delegates = delegates
        super.init(nibName: nil, bundle: nil)
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
        setupDelegates()
        setupObservers()
        viewModel.loadFirstMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatMessagesCollectionView.animationEnabled = true
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

private extension ChatViewController {
    func setupObservers() {
        viewModel.scrollDown
            .sink { [weak messagesCollectionView] _ in
                messagesCollectionView?.scrollToLastItem()
            }
            .store(in: &subscriptions)
        
        viewModel.messages
            .removeDuplicates()
            .combineLatest(viewModel.sender.removeDuplicates())
            .sink { [weak chatMessagesCollectionView] _ in
                chatMessagesCollectionView?.reloadDataWithFixedBottom()
            }
            .store(in: &subscriptions)
        
        viewModel.loadingStatus
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateLoadingViews() }
            .store(in: &subscriptions)
        
        viewModel.inputTextSetter
            .assign(to: \.text, on: inputBar)
            .store(in: &subscriptions)
        
        viewModel.showFreeTokensAlert
            .sink { [weak self] in self?.showFreeTokenAlert() }
            .store(in: &subscriptions)
    }
    
    func setupDelegates() {
        messagesCollectionView.messagesDataSource = delegates.dataSource
        messagesCollectionView.messagesLayoutDelegate = delegates.layoutDelegate
        messagesCollectionView.messagesDisplayDelegate = delegates.displayDelegate
        messageInputBar.delegate = delegates.inputBarDelegate
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
}
