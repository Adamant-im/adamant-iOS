//
//  FileListContainerView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Combine
import CommonKit
import FilesPickerKit
import SnapKit
import UIKit

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
        didSet { update(old: oldValue) }
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

extension FileListContainerView {
    fileprivate func configure() {
        addSubview(filesStack)
        filesStack.snp.makeConstraints { $0.directionalEdges.equalToSuperview() }
    }

    fileprivate func onAppear() {
        let filesToDownload = model.files
            .prefix(FilesConstants.maxFilesCount)
            .filter { $0.fileType.isMedia }

        guard !filesToDownload.isEmpty else { return }

        actionHandler(
            .autoDownloadContentIfNeeded(
                messageId: model.messageId,
                files: filesToDownload
            )
        )
    }

    fileprivate func update(old: ChatMediaContentView.FileModel) {
        if old.messageId != model.messageId { onAppear() }

        let fileList = model.files.prefix(FilesConstants.maxFilesCount)
        var processedFileIds = Set<String>()
        filesStack.arrangedSubviews.forEach { $0.isHidden = true }

        for (index, file) in fileList.enumerated() {
            let view = filesStack.arrangedSubviews[index] as? FileListContentView
            let isDuplicate = !processedFileIds.insert(file.file.id).inserted
            view?.isHidden = false
            view?.model = .init(
                chatFile: file,
                txStatus: model.txStatus,
                isDuplicate: isDuplicate
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
