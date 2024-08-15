//
//  FileListContainerView.swift
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

final class FileListContainerView: UIView {
    private lazy var filesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Self.stackSpacing
        
        for _ in 0..<FilesConstants.maxFilesCount {
            let view = FileListContentView()
            view.snp.makeConstraints { $0.height.equalTo(Self.cellSize) }
            stack.addArrangedSubview(view)
        }
        return stack
    }()
    
    // MARK: Proprieties
   
    static let stackSpacing: CGFloat = 8
    static let cellSize: CGFloat = 70
    
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

private extension FileListContainerView {
    func configure() {
        addSubview(filesStack)
        filesStack.snp.makeConstraints { $0.directionalEdges.equalToSuperview() }
    }
    
    func update() {
        let fileList = model.files.prefix(FilesConstants.maxFilesCount)
        
        let filesToDownload = fileList.filter {
            $0.fileType.isMedia
            && (
                (!$0.isCached && $0.isFullMediaDownloadAllowed)
                || (
                    $0.previewImage == nil
                    && $0.file.preview != nil
                    && $0.isPreviewDownloadAllowed
                )
            )
        }
        
        if !filesToDownload.isEmpty {
            actionHandler(.downloadContentIfNeeded(
                messageId: model.messageId,
                files: filesToDownload
            ))
        }
        
        filesStack.arrangedSubviews.forEach { $0.isHidden = true }

        for (index, file) in fileList.enumerated() {
            let view = filesStack.arrangedSubviews[index] as? FileListContentView
            view?.isHidden = false
            view?.model = .init(
                chatFile: file,
                txStatus: model.txStatus
            )
            view?.buttonActionHandler = { [weak self, file, model] in
                self?.actionHandler(
                    .openFile(
                        messageId: model.messageId,
                        file: file
                    )
                )
            }
        }
    }
}
