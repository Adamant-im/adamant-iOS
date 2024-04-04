//
//  ChatInputBar.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import InputBarAccessoryView
import SnapKit
import CommonKit

final class ChatInputBar: InputBarAccessoryView {
    var onAttachmentButtonTap: (() -> Void)?
    
    var fee = "" {
        didSet { updateFeeLabel() }
    }
    
    var isEnabled = true {
        didSet { updateIsEnabled() }
    }
    
    var isForcedSendEnabled = false {
        didSet { updateSendIsEnabled() }
    }
    
    var isAttachmentButtonEnabled = true {
        didSet { updateIsAttachmentButtonEnabled() }
    }
    
    var text: String {
        get { inputTextView.text }
        set { inputTextView.text = newValue }
    }
    
    private lazy var feeLabel = makeFeeLabel()
    private lazy var attachmentButton = makeAttachmentButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayerColors()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        sendButton.isEnabled = (isEnabled && !inputTextView.text.isEmpty) || isForcedSendEnabled
    }
    
    override func calculateIntrinsicContentSize() -> CGSize {
        let superSize = super.calculateIntrinsicContentSize()
        
        // Calculate the required height
        let superTopStackViewHeight = topStackView.arrangedSubviews.count > .zero
        ? topStackView.bounds.height
        : .zero
        
        let validTopStackViewHeight = topStackView.arrangedSubviews.map {
            $0.frame.height
        }.reduce(0, +)
        
        return .init(
            width: superSize.width,
            height: superSize.height
            - superTopStackViewHeight
            + validTopStackViewHeight
        )
    }
    
    override func inputTextViewDidChange() {
        super.inputTextViewDidChange()
        
        sendButton.isEnabled = isForcedSendEnabled
        ? true
        : sendButton.isEnabled
    }
}

private extension ChatInputBar {
    func updateFeeLabel() {
        feeLabel.setTitle(fee, for: .normal)
        feeLabel.setSize(feeLabel.titleLabel?.intrinsicContentSize ?? .zero, animated: false)
    }
    
    func updateIsEnabled() {
        inputTextView.isEditable = isEnabled
        sendButton.isEnabled = isEnabled
        attachmentButton.isEnabled = isEnabled
        
        inputTextView.placeholder = isEnabled
            ? .adamant.chat.messageInputPlaceholder
            : ""
            
        inputTextView.backgroundColor = isEnabled
            ? .adamant.chatInputFieldBarBackground
            : .adamant.chatInputBarBackground
        
        updateLayerColors()
        updateIsAttachmentButtonEnabled()
    }
    
    func updateSendIsEnabled() {
        sendButton.isEnabled = (isEnabled && !inputTextView.text.isEmpty) || isForcedSendEnabled
    }
    
    func updateIsAttachmentButtonEnabled() {
        let isEnabled = isEnabled && isAttachmentButtonEnabled
        
        attachmentButton.isEnabled = isEnabled
        attachmentButton.tintColor = isEnabled
            ? .adamant.primary
            : .adamant.disableBorderColor
    }
    
    func updateLayerColors() {
        let borderColor = isEnabled
            ? UIColor.adamant.chatInputBarBorderColor.cgColor
            : UIColor.adamant.disableBorderColor.cgColor
        
        sendButton.layer.borderColor = borderColor
        inputTextView.layer.borderColor = borderColor
    }
    
    func configure() {
        backgroundColor = .adamant.chatInputBarBackground
        backgroundView.backgroundColor = .adamant.chatInputBarBackground
        separatorLine.backgroundColor = .adamant.chatInputBarBorderColor
        
        configureLayout()
        configureSendButton()
        configureTextView()
        updateIsEnabled()
    }
    
    func configureLayout() {
        setStackViewItems([sendButton], forStack: .right, animated: false)
        setStackViewItems([feeLabel, .flexibleSpace], forStack: .bottom, animated: false)
        setStackViewItems([attachmentButton], forStack: .left, animated: false)
        
        // Adding spacing between leftStackView (attachment button) and message input field
        setLeftStackViewWidthConstant(
            to: attachmentButtonSize + baseInsetSize * 2,
            animated: false
        )
        
        leftStackView.layoutMargins = .init(
            top: .zero,
            left: .zero,
            bottom: .zero,
            right: baseInsetSize * 2
        )
        
        leftStackView.alignment = .bottom
        leftStackView.isLayoutMarginsRelativeArrangement = true
    }
    
    func configureSendButton() {
        sendButton.layer.cornerRadius = cornerRadius
        sendButton.layer.borderWidth = 1
        sendButton.tintColor = .adamant.primary
        sendButton.setSize(.init(width: buttonWidth, height: buttonHeight), animated: false)
        sendButton.title = nil
        sendButton.image = .asset(named: "Arrow")
    }
    
    func configureTextView() {
        inputTextView.autocorrectionType = .no
        inputTextView.placeholderTextColor = .adamant.chatPlaceholderTextColor
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.cornerRadius = cornerRadius
        inputTextView.layer.masksToBounds = true
        inputTextView.isImagePasteEnabled = false
        
        inputTextView.textContainerInset = .init(
            top: baseInsetSize + 2,
            left: baseInsetSize * 2,
            bottom: baseInsetSize - 2,
            right: baseInsetSize * 2
        )
        
        inputTextView.placeholderLabelInsets = .init(
            top: baseInsetSize + 2,
            left: baseInsetSize * 2 + 4,
            bottom: baseInsetSize - 2,
            right: baseInsetSize * 2
        )
        
        inputTextView.scrollIndicatorInsets = .init(
            top: baseInsetSize + 2,
            left: .zero,
            bottom: baseInsetSize + 2,
            right: .zero
        )
    }
    
    func makeAttachmentButton() -> InputBarButtonItem {
        let button = InputBarButtonItem().onTouchUpInside { [weak self] _ in
            self?.onAttachmentButtonTap?()
        }
        
        button.image = .asset(named: "Attachment")
        button.setSize(
            .init(width: attachmentButtonSize, height: attachmentButtonSize),
            animated: false
        )
        return button
    }
    
    func makeFeeLabel() -> InputBarButtonItem {
        let feeLabel = InputBarButtonItem()
        feeLabel.isEnabled = false
        feeLabel.titleLabel?.font = .systemFont(ofSize: 12)
        return feeLabel
    }
}

private let attachmentButtonSize: CGFloat = 36
private let baseInsetSize: CGFloat = 6
private let buttonHeight: CGFloat = 36
private let buttonWidth: CGFloat = 46
private let cornerRadius: CGFloat = 12
