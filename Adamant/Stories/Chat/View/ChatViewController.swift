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
        
        setupObservers()
        setupDelegates()
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
        
        viewModel.loadMessages()
    }
}

private extension ChatViewController {
    func setupObservers() {
        NotificationCenter.default.publisher(
            for: UITextView.textDidBeginEditingNotification,
            object: messageInputBar.inputTextView
        )
        .sink { [weak messagesCollectionView] _ in
            messagesCollectionView?.scrollToLastItem()
        }.store(in: &subscriptions)
        
        viewModel.messages
            .removeDuplicates()
            .combineLatest(viewModel.sender.removeDuplicates())
            .combineLatest(viewModel.loadingStatus.removeDuplicates())
            .sink { [weak messagesCollectionView] _ in
                messagesCollectionView?.reloadData(alignment: .bottom)
            }
            .store(in: &subscriptions)
        
        viewModel.loadingStatus
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateLoadingView() }
            .store(in: &subscriptions)
    }
    
    func setupDelegates() {
        messagesCollectionView.messagesDataSource = delegates.dataSource
        messagesCollectionView.messagesLayoutDelegate = delegates.layoutDelegate
        messagesCollectionView.messagesDisplayDelegate = delegates.displayDelegate
        messageInputBar.delegate = delegates.inputBarDelegate
    }
    
    func updateLoadingView() {
        let isLoading = viewModel.loadingStatus.value == .fullscreen
        loadingView.isHidden = !isLoading
        
        if isLoading {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }
}
