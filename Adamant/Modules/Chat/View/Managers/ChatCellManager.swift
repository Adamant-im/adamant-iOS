//
//  ChatCellManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import MessageKit

@MainActor
final class ChatCellManager: MessageCellDelegate {
    private let viewModel: ChatViewModel
    var getMessageId: ((MessageCollectionViewCell) -> String?)?
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    func didSelectURL(_ url: URL) {
        viewModel.didSelectURL(url)
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard
            let id = getMessageId?(cell),
            let message = viewModel.messages.first(where: { $0.id == id }),
            case .failed = message.status
        else { return }
        
        viewModel.dialog.send(.failedMessageAlert(id: id, sender: .view(cell)))
    }
}
