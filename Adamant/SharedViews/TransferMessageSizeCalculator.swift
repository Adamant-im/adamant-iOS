//
//  TransferMessageSizeCalculator.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import MessageKit

open class TransferMessageSizeCalculator: MessageSizeCalculator {
    let cellWidth: CGFloat = 87
    
    var font: UIFont! = nil
    
    override open func messageContainerSize(
        for message: MessageType,
        at indexPath: IndexPath
    ) -> CGSize {
        guard case MessageKind.custom(let raw) = message.kind, let transfer = raw as? RichMessageTransfer else {
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
        
        let amount = AdamantBalanceFormat.full.format(transfer.amount)
        
        var messageContainerSize = CGSize(width: cellWidth, height: TransferCollectionViewCell.cellHeightCompact)
        
        let maxWidth = messageContainerMaxWidth(for: message, at: indexPath)
        let attributedText = NSAttributedString(string: amount, attributes: [.font: font ?? .systemFont(ofSize: 24)])
        let constraintBox = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let rect = attributedText.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        
        messageContainerSize.width += rect.width
        
        if transfer.comments.count > 0 {
            let commentHeight = commentLabelHeight(for: transfer.comments, maxWidth: maxWidth)
            messageContainerSize.height += commentHeight
        }
        
        return messageContainerSize
    }
    
    open override func cellContentHeight(for message: MessageType, at indexPath: IndexPath) -> CGFloat {
        guard case MessageKind.custom(let raw) = message.kind, let transfer = raw as? RichMessageTransfer else {
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
        
        if transfer.comments.count > 0 {
            let maxWidth = messageContainerMaxWidth(for: message, at: indexPath)
            let commentHeight = commentLabelHeight(for: transfer.comments, maxWidth: maxWidth)
            return TransferCollectionViewCell.cellHeightWithComment + commentHeight
        } else {
            return TransferCollectionViewCell.cellHeightCompact
        }
    }
    
    private func commentLabelHeight(for comment: String, maxWidth: CGFloat) -> CGFloat {
        let commentAttributedText = NSAttributedString(string: comment, attributes: [.font: TransferCollectionViewCell.commentFont])
        let commentBox = CGSize(width: maxWidth - TransferCollectionViewCell.commentLabelTrailAndLead - TransferCollectionViewCell.statusImageSizeAndSpace, height: .greatestFiniteMagnitude)
        let commentRect = commentAttributedText.boundingRect(with: commentBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        
        return commentRect.height
    }
}

extension NSAttributedString {
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}
