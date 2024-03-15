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

final class ChatMediaContentView: UIView {
    private let commentLabel = UILabel(
        font: commentFont,
        textColor: .adamant.textColor,
        numberOfLines: .zero
    )
    
    var replyViewDynamicHeight: CGFloat {
        model.isReply ? replyViewHeight : 0
    }
    
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
    
    private lazy var verticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [replyView, commentLabel, filesStack])
        stack.axis = .vertical
        stack.spacing = verticalStackSpacing
        return stack
    }()
    
    private lazy var filesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = verticalStackSpacing
        
        for _ in 0..<FilesConstants.maxFilesCount {
            let view = ChatFileView()
            view.snp.makeConstraints { $0.height.equalTo(imageSize) }
            stack.addArrangedSubview(view)
        }
        return stack
    }()

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
}

private extension ChatMediaContentView {
    func configure() {
        layer.cornerRadius = 16
        
        addSubview(verticalStack)
        verticalStack.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(8)
            make.horizontalEdges.equalToSuperview().inset(12)
        }
    }
    
    func update() {
        alpha = model.isHidden ? .zero : 1.0
        backgroundColor = model.backgroundColor.uiColor
        
        commentLabel.attributedText = model.comment
        commentLabel.isHidden = model.comment.string.isEmpty
        replyView.isHidden = !model.isReply
        
        if model.isReply {
            replyMessageLabel.attributedText = model.replyMessage
        } else {
            replyMessageLabel.attributedText = nil
        }
        
        replyView.snp.updateConstraints { make in
            make.height.equalTo(replyViewDynamicHeight)
        }
       
        updateStackLayout()
    }
    
    func updateStackLayout() {
        let fileList = model.files.prefix(FilesConstants.maxFilesCount)
        
        filesStack.arrangedSubviews.forEach { $0.isHidden = true }
        
        for (index, file) in fileList.enumerated() {
            let view = filesStack.arrangedSubviews[index] as? ChatFileView
            view?.isHidden = false
            view?.model = file
            view?.buttonActionHandler = { [actionHandler, file, model] in
                actionHandler(
                    .processFile(
                        file: file,
                        isFromCurrentSender: model.isFromCurrentSender
                    )
                )
            }
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
        let replyViewDynamicHeight: CGFloat = isReply ? replyViewHeight : 0
        
        let filesCount = files.count > FilesConstants.maxFilesCount
        ? FilesConstants.maxFilesCount
        : files.count
        
        let stackSpacingCount: CGFloat = isReply 
        ? CGFloat(filesCount) + 1
        : CGFloat(filesCount)

        return imageSize * CGFloat(filesCount)
        + stackSpacingCount * verticalStackSpacing
        + labelSize(for: comment, considering: contentWidth).height
        + replyViewDynamicHeight
    }
    
    func labelSize(
       for attributedText: NSAttributedString,
       considering maxWidth: CGFloat
    ) -> CGSize {
        let textContainer = NSTextContainer(
           size: CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        )
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addLayoutManager(layoutManager)
        
        let rect = layoutManager.usedRect(for: textContainer)
        
        return rect.integral.size
    }
}

private let nameFont = UIFont.systemFont(ofSize: 15)
private let sizeFont = UIFont.systemFont(ofSize: 13)
private let imageSize: CGFloat = 90
private typealias TransactionsDiffableDataSource = UITableViewDiffableDataSource<Int, ChatFile>
private let cellIdentifier = "cell"
private let commentFont = UIFont.systemFont(ofSize: 14)
private let verticalStackSpacing: CGFloat = 6
private let verticalInsets: CGFloat = 8
private let replyViewHeight: CGFloat = 25
private let contentWidth: CGFloat = 260
