//
//  MediaContainerView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SnapKit
import UIKit
import CommonKit
import FilesPickerKit

final class MediaContainerView: UIView {
    private lazy var filesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = stackSpacing
        stack.alignment = .fill
        stack.distribution = .fill
        stack.layer.masksToBounds = true
        
        for chunk in 0..<(FilesConstants.maxFilesCount / 2) {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = stackSpacing
            stackView.alignment = .fill
            stackView.distribution = .fill
            
            for file in 0..<2 {
                let view = MediaContentView()
                view.layer.masksToBounds = true
                view.snp.makeConstraints {
                    $0.height.equalTo(rowVerticalHeight)
                }
                stackView.addArrangedSubview(view)
            }
            
            stack.addArrangedSubview(stackView)
        }
        
        return stack
    }()
    
    private lazy var previewDownloadNotAllowedLabel = EdgeInsetLabel(
        font: previewDownloadNotAllowedFont,
        textColor: .adamant.textColor.withAlphaComponent(0.4)
    )
    
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

private extension MediaContainerView {
    func configure() {
        layer.masksToBounds = true
        
        addSubview(filesStack)
        filesStack.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
            $0.width.equalTo(model.width())
        }
        
        addSubview(previewDownloadNotAllowedLabel)
        previewDownloadNotAllowedLabel.snp.makeConstraints { make in
            make.center.equalTo(filesStack.snp.center)
        }
        
        previewDownloadNotAllowedLabel.textInsets = previewTextInsets
        previewDownloadNotAllowedLabel.text = previewDownloadNotAllowedText
        previewDownloadNotAllowedLabel.numberOfLines = .zero
        previewDownloadNotAllowedLabel.textAlignment = .center
        previewDownloadNotAllowedLabel.backgroundColor = .adamant.moreReactionsBackground.withAlphaComponent(0.2)
        previewDownloadNotAllowedLabel.layer.cornerRadius = 6
        previewDownloadNotAllowedLabel.addShadow(shadowColor: .adamant.primary)
        previewDownloadNotAllowedLabel.clipsToBounds = true
        previewDownloadNotAllowedLabel.sizeToFit()
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
        
        updatePreviewDownloadLabel(files: Array(fileList))
        
        for (index, stackView) in filesStack.arrangedSubviews.enumerated() {
            guard let horizontalStackView = stackView as? UIStackView else { continue }
            
            var isHorizontal = false
            
            for (fileIndex, fileView) in horizontalStackView.arrangedSubviews.enumerated() {
                guard let mediaView = fileView as? MediaContentView else { continue }
                
                let fileOverallIndex = index * horizontalStackView.arrangedSubviews.count + fileIndex
                
                if fileOverallIndex < fileList.count {
                    let file = fileList[fileOverallIndex]
                    mediaView.isHidden = false
                    mediaView.model = .init(
                        chatFile: file,
                        txStatus: model.txStatus
                    )
                    mediaView.buttonActionHandler = { [weak self, file, model] in
                        self?.actionHandler(
                            .openFile(
                                messageId: model.messageId,
                                file: file
                            )
                        )
                    }

                    if let resolution = file.file.resolution,
                       resolution.width > resolution.height {
                        isHorizontal = true
                    }
                } else {
                    mediaView.isHidden = true
                }
            }
            
            updateCellsSize(
                in: horizontalStackView,
                isHorizontal: isHorizontal,
                fileList: Array(fileList)
            )
        }
    }
    
    func updateCellsSize(
        in horizontalStackView: UIStackView,
        isHorizontal: Bool,
        fileList: [ChatFile]
    ) {
        let filesStackWidth = model.width()

        let minimumWidth = calculateMinimumWidth(availableWidth: filesStackWidth)
        let maximumWidth = calculateMaximumWidth(availableWidth: filesStackWidth)
        
        let height: CGFloat = isHorizontal
        ? rowHorizontalHeight
        : fileList.count == 1 ? rowVerticalHeight * 2 : rowVerticalHeight

        var totalWidthForEqualAspectRatio: CGFloat = 0.0
        
        for case let mediaView as MediaContentView in horizontalStackView.arrangedSubviews {
            if let resolution = mediaView.model.chatFile.file.resolution {
                let aspectRatio = resolution.width / resolution.height
                let widthForEqualAspectRatio = height * aspectRatio
                totalWidthForEqualAspectRatio += widthForEqualAspectRatio
            } else {
                totalWidthForEqualAspectRatio += height
            }
        }

        let scaleFactor = filesStackWidth / totalWidthForEqualAspectRatio

        for case let mediaView as MediaContentView in horizontalStackView.arrangedSubviews {
            if let resolution = mediaView.model.chatFile.file.resolution {
                let aspectRatio = resolution.width / resolution.height
                let widthForEqualAspectRatio = height * aspectRatio
                var width = max(widthForEqualAspectRatio * scaleFactor, minimumWidth)
                width = min(width, maximumWidth)
                
                mediaView.snp.remakeConstraints {
                    $0.width.equalTo(width - stackSpacing)
                    $0.height.equalTo(height)
                }
            } else {
                mediaView.snp.remakeConstraints {
                    $0.height.equalTo(height)
                    $0.width.equalTo((filesStackWidth - stackSpacing) / 2)
                }
            }
        }
    }
    
    func calculateMinimumWidth(availableWidth: CGFloat) -> CGFloat {
        (availableWidth - stackSpacing) * 0.3
    }
    
    func calculateMaximumWidth(availableWidth: CGFloat) -> CGFloat {
        (availableWidth - stackSpacing) * 0.7
    }
    
    func updatePreviewDownloadLabel(files: [ChatFile]) {
        guard let firstFile = files.first else {
            previewDownloadNotAllowedLabel.isHidden = true
            return
        }

        let isPreviewDownloadAllowed = firstFile.isPreviewDownloadAllowed
        let haveNoPreview = files.contains {
            $0.fileType.isMedia 
            && $0.previewImage == nil
            && $0.file.preview != nil
        }

        if !isPreviewDownloadAllowed && haveNoPreview {
            previewDownloadNotAllowedLabel.isHidden = false
        } else {
            previewDownloadNotAllowedLabel.isHidden = true
        }
    }
}

extension ChatMediaContentView.FileModel {
    @MainActor
    func height() -> CGFloat {
        let fileList = Array(files.prefix(FilesConstants.maxFilesCount))
        
        guard isMediaFilesOnly else {
            return FileListContainerView.cellSize * CGFloat(fileList.count)
            + FileListContainerView.stackSpacing * CGFloat(fileList.count)
        }
        
        let rows = fileList.chunked(into: 2)
        var totalHeight: CGFloat = .zero
        
        for row in rows {
            var isHorizontal = false
            for row in row {
                if let resolution = row.file.resolution,
                   resolution.width > resolution.height {
                    isHorizontal = true
                }
            }
            
            let height: CGFloat = isHorizontal
            ? rowHorizontalHeight
            : fileList.count == 1 ? rowVerticalHeight * 2 : rowVerticalHeight
            
            totalHeight += height
        }
        
        return totalHeight
        + stackSpacing * CGFloat(rows.count)
    }
}

private let stackSpacing: CGFloat = 1
private let rowVerticalHeight: CGFloat = 200
private let rowHorizontalHeight: CGFloat = 150
private let defaultStackWidth: CGFloat = 280
private let screenSpace: CGFloat = 110
private let previewDownloadNotAllowedFont = UIFont.systemFont(ofSize: 12)
private let previewTextInsets: UIEdgeInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
private var previewDownloadNotAllowedText: String { .localized("Chats.AutoDownloadPreview.Disabled") }
