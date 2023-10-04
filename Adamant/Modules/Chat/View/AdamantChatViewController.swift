//
//  AdamantChatViewController.swift
//  Adamant
//
//  Created by Andrew G on 09.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import ChatKit
import Combine
import UIKit

final class AdamantChatViewController: ChatViewController {
    let viewModel: ChatMessagesViewModel
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(viewModel: ChatMessagesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.loadMessages()
        
        viewModel.$state.map(\.messages).sink { [weak self] in
            self?.model.items = $0
        }.store(in: &subscriptions)
    }
}
