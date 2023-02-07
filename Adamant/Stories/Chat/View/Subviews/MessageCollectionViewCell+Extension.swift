//
//  MessageCollectionViewCell+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import Foundation

extension MessageCollectionViewCell {
    @objc func remove() {
        guard
            let collectionView = superview as? ChatMessagesCollectionView<ChatMessage>,
            let indexPath = collectionView.indexPath(for: self)
        else { return }
        
        collectionView.removeMessageAction?(indexPath)
    }

    @objc func report() {
        guard
            let collectionView = superview as? ChatMessagesCollectionView<ChatMessage>,
            let indexPath = collectionView.indexPath(for: self)
        else { return }
        
        collectionView.reportMessageAction?(indexPath)
    }
}
