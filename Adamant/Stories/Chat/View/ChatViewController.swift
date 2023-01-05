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
    
    private let delegates: Delegates
    private var subscriptions = Set<AnyCancellable>()
    
    private let inputBar = ChatInputBar()
    private let loadingView = LoadingView()
    
    let viewModel: ChatViewModel
    
    // swiftlint:disable unused_setter_value
    override var messageInputBar: InputBarAccessoryView {
        get { inputBar }
        set { assertionFailure("Do not set messageInputBar") }
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
        messagesCollectionView.backgroundColor = .adamant.backgroundColor
        messagesCollectionView.register(
            SpinnerCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )
        
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        setupDelegates()
        setupObservers()

        // Content insets are not set yet and we can't correctly display messages on the screen.
        // So loadFirstMessages() is not called in this task. We need to add it to the queue
        DispatchQueue.main.async(execute: viewModel.loadFirstMessages)
    }
    
    override func collectionView(
        _: UICollectionView,
        willDisplay _: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard indexPath.section < 4 else { return }
        viewModel.loadMoreMessagesIfNeeded()
    }
}

private extension ChatViewController {
    func setupObservers() {
        NotificationCenter.default.publisher(
            for: UITextView.textDidBeginEditingNotification,
            object: messageInputBar.inputTextView
        )
        .combineLatest(viewModel.scrollDown)
        .sink { [weak messagesCollectionView] _ in
            messagesCollectionView?.scrollToLastItem()
        }.store(in: &subscriptions)
        
        viewModel.messages
            .removeDuplicates()
            .combineLatest(viewModel.sender.removeDuplicates())
            .sink { [weak messagesCollectionView] _ in
                messagesCollectionView?.reloadDataWithFixedBottom()
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
                messagesCollectionView.reloadSectionsWithFixedBottom(.init(integer: .zero))
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
