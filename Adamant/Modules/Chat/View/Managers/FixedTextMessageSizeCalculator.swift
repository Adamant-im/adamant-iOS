//
 //  FixedTextMessageSizeCalculator.swift
 //  Adamant
 //
 //  Created by Andrey Golubenko on 19.04.2023.
 //  Copyright © 2023 Adamant. All rights reserved.
 //

import UIKit
@preconcurrency import MessageKit

final class FixedTextMessageSizeCalculator: MessageSizeCalculator, @unchecked Sendable {
     private let getCurrentSender: () -> SenderType
     private let getMessages: () -> [ChatMessage]
     private let messagesFlowLayout: MessagesCollectionViewFlowLayout
     
     init(
         layout: MessagesCollectionViewFlowLayout,
         getCurrentSender: @escaping () -> SenderType,
         getMessages: @escaping () -> [ChatMessage]
     ) {
         self.getMessages = getMessages
         self.getCurrentSender = getCurrentSender
         self.messagesFlowLayout = layout
         super.init()
         self.layout = layout
     }
     
     override func messageContainerMaxWidth(
         for message: MessageType,
         at indexPath: IndexPath
     ) -> CGFloat {
         let maxWidth = super.messageContainerMaxWidth(for: message, at: indexPath)
         let textInsets = messageLabelInsets(for: message)
         return maxWidth - textInsets.horizontal
     }

     override func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
         MainActor.assumeIsolatedSafe {
             let maxWidth = messageContainerMaxWidth(for: message, at: indexPath)

             var messageContainerSize: CGSize = .zero
             let messageInsets = messageLabelInsets(for: message)

             if case let .message(model) = getMessages()[indexPath.section].fullModel.content {
                 messageContainerSize = labelSize(for: model.value.text, considering: maxWidth)
                 messageContainerSize.width += messageInsets.horizontal
                 messageContainerSize.height += messageInsets.vertical
             }
             
             if case let .reply(model) = getMessages()[indexPath.section].fullModel.content {
                 let messageSize = labelSize(
                    for: model.value.message,
                    considering: maxWidth
                 )
                 
                 let messageReplySize = labelSize(
                    for: model.value.messageReply,
                    considering: maxWidth
                 )
                 
                 let size = messageSize.width > messageReplySize.width
                 ? messageSize
                 : messageReplySize
                 
                 let contentViewHeight = model.value.contentHeight(
                    for: size.width + messageInsets.horizontal / 2
                 )
                 
                 messageContainerSize = size
                 messageContainerSize.width += messageInsets.horizontal
                 + additionalWidth
                 messageContainerSize.height = contentViewHeight
             }
             
             if case let .transaction(model) = getMessages()[indexPath.section].fullModel.content {
                 let contentViewHeight = model.value.height(for: maxWidth)
                 messageContainerSize.width = maxWidth
                 messageContainerSize.height = contentViewHeight
                 + messageInsets.vertical
                 + additionalHeight
             }
             
             if case let .file(model) = getMessages()[indexPath.section].fullModel.content {
                 let messageSize = labelSize(
                    for: model.value.content.comment,
                    considering: model.value.content.width()
                    - commenthorizontalInsets * 2
                 )
                 
                 let contentViewHeight = model.value.height()
                 messageContainerSize.width = maxWidth
                 messageContainerSize.height = contentViewHeight
                 + messageSize.height
             }
             
             return messageContainerSize
         }
     }

     override func configure(attributes: UICollectionViewLayoutAttributes) {
         super.configure(attributes: attributes)
         MainActor.assumeIsolatedSafe {
             guard let attributes = attributes as? MessagesCollectionViewLayoutAttributes else { return }

             let dataSource = messagesLayout.messagesDataSource
             let indexPath = attributes.indexPath

             let message = dataSource.messageForItem(
                 at: indexPath,
                 in: messagesLayout.messagesCollectionView
             )

             attributes.messageLabelInsets = messageLabelInsets(for: message)
             attributes.messageLabelFont = messageLabelFont

             switch message.kind {
             case .attributedText(let text):
                 guard
                     !text.string.isEmpty,
                     let font = text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
                 else { break }

                 attributes.messageLabelFont = font
             default:
                 break
             }
         }
     }
 }

 private extension FixedTextMessageSizeCalculator {
     func messageLabelInsets(for message: MessageType) -> UIEdgeInsets {
         MainActor.assumeIsolatedSafe {
             let dataSource = messagesLayout.messagesDataSource
             let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
             return isFromCurrentSender
                 ? outgoingMessageLabelInsets
                 : incomingMessageLabelInsets
         }
     }

     func labelSize(
        for attributedText: NSAttributedString,
        considering maxWidth: CGFloat
     ) -> CGSize {
         guard !attributedText.string.isEmpty else { return .zero }
         
         let textContainer = NSTextContainer(
            size: CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
         )
         textContainer.lineFragmentPadding = .zero
         
         let layoutManager = NSLayoutManager()
         
         layoutManager.addTextContainer(textContainer)
         
         let textStorage = NSTextStorage(attributedString: attributedText)
         textStorage.addLayoutManager(layoutManager)
         
         let rect = layoutManager.usedRect(for: textContainer)
         
         return rect.integral.size
     }
 }

 private extension UIEdgeInsets {
     var vertical: CGFloat {
         top + bottom
     }

     var horizontal: CGFloat {
         left + right
     }
 }

 private extension MessageKind {
     var textMessageKind: MessageKind {
         switch self {
         case .linkPreview(let linkItem):
             return linkItem.textKind
         case .text, .emoji, .attributedText:
             return self
         default:
             assertionFailure("textMessageKind not supported for messageKind: \(self)")
             return .text("")
         }
     }
 }

 private let incomingMessageLabelInsets = UIEdgeInsets(top: 7, left: 18, bottom: 7, right: 14)
 private let outgoingMessageLabelInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 18)
 private let messageLabelFont = UIFont.preferredFont(forTextStyle: .body)

 /// Additional width to fix incorrect size calculating
private let additionalWidth: CGFloat = 5
private let additionalHeight: CGFloat = 5
private let commenthorizontalInsets: CGFloat = 12
