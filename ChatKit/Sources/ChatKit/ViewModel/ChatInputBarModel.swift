//
//  ChatInputBarModel.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import CommonKit

public struct ChatInputBarModel: Equatable {
    public var reply: String?
    public var placeholder: String
    public var text: String
    public var fee: String?
    public var isEnabled: Bool
    public var isAttachmentButtonEnabled: Bool
    public var onAttachmentButtonTap: HashableAction?
    public var onSendButtonTap: HashableAction?

    public static let `default` = Self(
        placeholder: .empty,
        text: .empty,
        isEnabled: true,
        isAttachmentButtonEnabled: true
    )
}
