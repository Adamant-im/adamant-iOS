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
        
        for chunk in 0..<3 {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 1
            stackView.alignment = .fill
            stackView.distribution = .fillEqually
            
            for file in 0..<2 {
                let view = MediaContentView()
                view.layer.masksToBounds = true
                view.snp.makeConstraints {
                    $0.height.equalTo(rowHeight)
                }
                stackView.addArrangedSubview(view)
            }
            
            stack.addArrangedSubview(stackView)
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

private extension MediaContainerView {
    func configure() {
        addSubview(filesStack)
        filesStack.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
            $0.width.equalTo(stackWidth)
        }
    }
    
    func update() {
        let fileList = model.files.prefix(FilesConstants.maxFilesCount)
        for (index, stackView) in filesStack.arrangedSubviews.enumerated() {
            guard let horizontalStackView = stackView as? UIStackView else { continue }
            
            for (fileIndex, fileView) in horizontalStackView.arrangedSubviews.enumerated() {
                guard let mediaView = fileView as? MediaContentView else { continue }
                
                let fileOverallIndex = index * horizontalStackView.arrangedSubviews.count + fileIndex
                
                if fileOverallIndex < fileList.count {
                    let file = fileList[fileOverallIndex]
                    mediaView.isHidden = false
                    mediaView.model = file
                    mediaView.buttonActionHandler = { [actionHandler, file, model] in
                        actionHandler(
                            .processFile(
                                file: file,
                                isFromCurrentSender: model.isFromCurrentSender
                            )
                        )
                    }
                } else {
                    mediaView.isHidden = true
                }
            }
        }
    }
}

private let stackSpacing: CGFloat = 1
private let rowHeight: CGFloat = 290
private let stackWidth: CGFloat = 280

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension ChatMediaContentView.FileModel {
    func height() -> CGFloat {
        let fileList = Array(files.prefix(FilesConstants.maxFilesCount))
        
        guard isMediaFilesOnly else {
            return 70 * CGFloat(fileList.count)
        }
        
        let rowCount = fileList.chunked(into: 2).count
        
        return rowHeight * CGFloat(rowCount)
        + stackSpacing * CGFloat(rowCount)
    }
}
