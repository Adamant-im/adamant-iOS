//
//  ChatCellManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import MessageKit

final class ChatCellManager: MessageCellDelegate {
    private let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    func didSelectURL(_ url: URL) {
        viewModel.didSelectURL(url)
    }
}
