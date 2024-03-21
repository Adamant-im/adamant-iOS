//
//  FileContainerView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SnapKit
import UIKit
import CommonKit
import FilesPickerKit
import Combine

final class FileContainerView: UIView {
    private lazy var filesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = stackSpacing
        
        for _ in 0..<FilesConstants.maxFilesCount {
            let view = ChatFileView()
            view.snp.makeConstraints { $0.height.equalTo(cellSize) }
            stack.addArrangedSubview(view)
        }
        return stack
    }()
    
    // MARK: Proprieties
    
    var model: ChatMediaContentView.FileModel = .default {
        didSet { update() }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension FileContainerView {
    func configure() {
        addSubview(filesStack)
        filesStack.snp.makeConstraints { $0.directionalEdges.equalToSuperview() }
    }
    
    func update() {
        let fileList = model.files.prefix(FilesConstants.maxFilesCount)
        
        filesStack.arrangedSubviews.forEach { $0.isHidden = true }

        for (index, file) in fileList.enumerated() {
            let view = filesStack.arrangedSubviews[index] as? ChatFileView
            view?.isHidden = false
            view?.model = file
            view?.buttonActionHandler = { [actionHandler, file, model] in
                actionHandler(
                    .openFile(
                        messageId: model.messageId,
                        file: file,
                        isFromCurrentSender: model.isFromCurrentSender
                    )
                )
            }
        }
    }
}

private let stackSpacing: CGFloat = 8
private let cellSize: CGFloat = 70
