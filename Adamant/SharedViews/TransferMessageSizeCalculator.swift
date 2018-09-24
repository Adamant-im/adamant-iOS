//
//  TransferMessageSizeCalculator.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import MessageKit

class TransferMessageSizeCalculator: MessageSizeCalculator {
    let cellWidth: CGFloat = 87
    var font: UIFont! = nil
    
    override func messageContainerSize(for message: MessageType) -> CGSize {
        guard case MessageKind.custom(let raw) = message.kind, let richContent = raw as? [String:String] else {
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
        
        let amount = richContent[RichContentKeys.transfer.amount] ?? "NaN"
        
        var messageContainerSize = CGSize(width: cellWidth, height: 129)
        
        let maxWidth = messageContainerMaxWidth(for: message)
        let attributedText = NSAttributedString(string: amount, attributes: [.font: font])
        let constraintBox = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let rect = attributedText.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        
//        messageContainerSize.width += rect.width
        
        return messageContainerSize
    }
}

extension NSAttributedString {
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}
