//
//  ChatMediaContnentView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SnapKit
import UIKit
import CommonKit
import FilesPickerKit
import MessageKit

final class ChatMediaContentView: UIView {
    private let commentLabel = MessageLabel()
    
    private let spacingView: UIView = {
        let view = UIView()
        view.snp.makeConstraints { $0.height.equalTo(verticalInsets) }
        return view
    }()
    
    private var replyMessageLabel = UILabel()
    
    private lazy var colorView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .adamant.active
        return view
    }()
    
    private lazy var replyView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray.withAlphaComponent(0.15)
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        
        view.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(didTap)
        ))
        
        view.addSubview(colorView)
        view.addSubview(replyMessageLabel)
        
        replyMessageLabel.numberOfLines = 1
        
        colorView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(2)
        }
        replyMessageLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-5)
            $0.leading.equalTo(colorView.snp.trailing).offset(6)
        }
        view.snp.makeConstraints { make in
            make.height.equalTo(replyViewDynamicHeight)
        }
        return view
    }()
    
    private lazy var replyContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        
        view.addSubview(replyView)
        
        replyView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(verticalInsets)
            make.horizontalEdges.equalToSuperview().inset(horizontalInsets)
            make.bottom.equalToSuperview()
        }
        
        view.snp.makeConstraints { make in
            make.height.equalTo(replyContainerViewDynamicHeight)
        }
        return view
    }()
    
    private lazy var listFileContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        
        view.addSubview(fileContainerView)
        
        fileContainerView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(verticalInsets)
            make.horizontalEdges.equalToSuperview().inset(horizontalInsets)
        }
        
        return view
    }()
    
    private lazy var commentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        
        view.addSubview(commentLabel)
        
        commentLabel.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(verticalInsets)
            make.horizontalEdges.equalToSuperview().inset(horizontalInsets)
        }
        
        return view
    }()
    
    private lazy var verticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [replyContainerView, spacingView, mediaContainerView, listFileContainerView, commentContainerView])
        stack.axis = .vertical
        stack.spacing = .zero
        stack.layer.masksToBounds = true
        return stack
    }()
    
    private lazy var uploadImageView = UIImageView(image: .asset(named: "downloadIcon"))
    
    private lazy var mediaContainerView = MediaContainerView()
    private lazy var fileContainerView = FileListContainerView()
    
    var replyViewDynamicHeight: CGFloat {
        model.isReply ? replyViewHeight : .zero
    }
    
    var replyContainerViewDynamicHeight: CGFloat {
        model.isReply
        ? replyViewHeight + verticalInsets
        : .zero
    }
    
    var model: Model = .default {
        didSet {
            guard oldValue != model else { return }
            update()
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            animateIsSelected(
                isSelected,
                originalColor: model.backgroundColor.uiColor
            )
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        layer.borderColor = model.backgroundColor.uiColor.cgColor
    }
}

private extension ChatMediaContentView {
    func configure() {
        layer.masksToBounds = true
        layer.cornerRadius = 16
        layer.borderWidth = 2.5
        
        addSubview(verticalStack)
        verticalStack.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        addSubview(uploadImageView)
        uploadImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(imageSize)
        }
        
        uploadImageView.transform = CGAffineTransform(rotationAngle: .pi)
        
        commentLabel.enabledDetectors = [.url]
        commentLabel.setAttributes([.foregroundColor: UIColor.adamant.active], detector: .url)
    }
    
    func update() {
        alpha = model.isHidden ? .zero : 1.0
        backgroundColor = model.backgroundColor.uiColor
        layer.borderColor = model.backgroundColor.uiColor.cgColor
        
        uploadImageView.isHidden = model.fileModel.txStatus != .failed
        
        commentLabel.attributedText = model.comment
        commentLabel.isHidden = model.comment.string.isEmpty
        commentContainerView.isHidden = model.comment.string.isEmpty
        replyContainerView.isHidden = !model.isReply
        spacingView.isHidden = !model.fileModel.isMediaFilesOnly
        
        replyMessageLabel.attributedText = model.isReply
        ? model.replyMessage
        : nil
        
        replyContainerView.snp.updateConstraints { make in
            make.height.equalTo(replyContainerViewDynamicHeight)
        }
        
        let spaceHeight = model.fileModel.isMediaFilesOnly && model.isReply
        ? verticalInsets
        : .zero
        spacingView.snp.remakeConstraints { $0.height.equalTo(spaceHeight) }
        
        updateStackLayout()
    }
    
    func updateStackLayout() {
        spacingView.isHidden = !model.fileModel.isMediaFilesOnly
        mediaContainerView.isHidden = !model.fileModel.isMediaFilesOnly
        listFileContainerView.isHidden = model.fileModel.isMediaFilesOnly
        
        if model.fileModel.isMediaFilesOnly {
            mediaContainerView.actionHandler = actionHandler
            mediaContainerView.model = model.fileModel
        } else {
            fileContainerView.actionHandler = actionHandler
            fileContainerView.model = model.fileModel
        }
    }
    
    @objc func didTap() {
        actionHandler(.scrollTo(message: .init(
            id: model.id,
            replyId: model.replyId,
            message: NSAttributedString(string: .empty),
            messageReply: NSAttributedString(string: .empty),
            backgroundColor: .failed,
            isFromCurrentSender: true,
            reactions: nil,
            address: .empty,
            opponentAddress: .empty,
            isHidden: false
        )))
    }
}

extension ChatMediaContentView.Model {
    func height() -> CGFloat {
        let replyViewDynamicHeight: CGFloat = isReply ? replyViewHeight : .zero
        
        var spaceCount: CGFloat = fileModel.isMediaFilesOnly ? .zero : 1
        
        if isReply {
            spaceCount += 2
        }
        
        if !comment.string.isEmpty {
            spaceCount += 2
        }
        
        let stackWidth = MediaContainerView.stackWidth
        
        return fileModel.height()
        + spaceCount * verticalInsets
        + labelSize(for: comment, considering: stackWidth - horizontalInsets * 2).height
        + replyViewDynamicHeight
    }
    
    func labelSize(
       for attributedText: NSAttributedString,
       considering maxWidth: CGFloat
    ) -> CGSize {
        guard !attributedText.string.isEmpty else { return .zero }
        
        let textContainer = NSTextContainer(
           size: CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        )
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addLayoutManager(layoutManager)
        
        let rect = layoutManager.usedRect(for: textContainer)
        
        return .init(width: rect.width, height: rect.height + additionalHeight)
    }
}

private let verticalInsets: CGFloat = 8
private let horizontalInsets: CGFloat = 12
private let replyViewHeight: CGFloat = 25
private let additionalHeight: CGFloat = 2
private let imageSize: CGFloat = 70
