//
//  ChatDisplayManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import Combine

@MainActor
final class ChatDisplayManager: MessagesDisplayDelegate {
    private let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    func messageStyle(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> MessageStyle {
        .bubbleTail(
            message.sender.senderId == viewModel.sender.senderId
                ? .bottomRight
                : .bottomLeft,
            .curved
        )
    }
    
    func backgroundColor(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> UIColor {
        message.fullModel.backgroundColor.uiColor
    }
    
    func textColor(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> UIColor { .adamant.primary }
    
    func messageHeaderView(
        for indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageReusableView {
        let header = messagesCollectionView.dequeueReusableHeaderView(
            ChatViewController.SpinnerCell.self,
            for: indexPath
        )
        
        if viewModel.messages[indexPath.section].topSpinnerOn {
            header.wrappedView.startAnimating()
        } else {
            header.wrappedView.stopAnimating()
        }
        
        return header
    }
    
    func enabledDetectors(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> [DetectorType] {
        return [.url]
    }
    
    func detectorAttributes(
        for detector: DetectorType,
        and _: MessageType,
        at _: IndexPath
    ) -> [NSAttributedString.Key: Any] {
        return detector == .url
            ? [.foregroundColor: UIColor.adamant.active]
            : [:]
    }
    
    func configureAccessoryView(
        _ accessoryView: UIView,
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) {
        switch message.fullModel.status {
        case .failed:
            guard accessoryView.subviews.isEmpty else { break }
            let icon = UIImageView(frame: CGRect(x: -28, y: -10, width: 20, height: 20))
            icon.contentMode = .scaleAspectFit
            icon.tintColor = .adamant.secondary
            icon.image = #imageLiteral(resourceName: "cross").withRenderingMode(.alwaysTemplate)
            accessoryView.addSubview(icon)
        case .delivered, .pending:
            accessoryView.subviews.forEach { $0.removeFromSuperview() }
        }
    }
}
