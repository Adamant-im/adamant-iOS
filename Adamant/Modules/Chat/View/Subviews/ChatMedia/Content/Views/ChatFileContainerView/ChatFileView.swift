//
//  ChatFileTableViewCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit
import SwiftUI

class ChatFileView: UIView {
    private lazy var iconImageView: UIImageView = UIImageView()
    private lazy var downloadImageView = UIImageView(image: .asset(named: "downloadIcon"))
    private lazy var videoIconIV = UIImageView(image: .asset(named: "playVideoIcon"))

    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.isHidden = true
        view.color = .white
        view.backgroundColor = .darkGray.withAlphaComponent(0.45)
        return view
    }()
    
    private lazy var horizontalStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = stackSpacing
        
        stack.addArrangedSubview(iconImageView)
        stack.addArrangedSubview(vStack)
        return stack
    }()
    
    private let nameLabel = UILabel(font: nameFont, textColor: .adamant.textColor)
    private let sizeLabel = UILabel(font: sizeFont, textColor: .lightGray)
    private let additionalLabel = UILabel(font: additionalFont, textColor: .adamant.cellColor)
    
    private lazy var previewDownloadNotAllowedLabel = UILabel(
        font: previewDownloadNotAllowedFont,
        textColor: .adamant.textColor.withAlphaComponent(0.4)
    )
    
    private lazy var vStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = verticalStackSpacing
        stack.backgroundColor = .clear

        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(additionalDataStack)
        return stack
    }()
    
    private lazy var additionalDataStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = stackSpacing
        
        let controller = UIHostingController(rootView: progressBar.environmentObject(progressState))
        controller.view.backgroundColor = .clear
        
        stack.addArrangedSubview(sizeLabel)
        stack.addArrangedSubview(controller.view)
        return stack
    }()
    
    private lazy var tapBtn: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(tapBtnAction), for: .touchUpInside)
        return btn
    }()
    
    private lazy var progressBar = CircularProgressView()
    private lazy var progressState: CircularProgressState = {
        .init(
            lineWidth: 2.0,
            backgroundColor: .white,
            progressColor: .lightGray,
            progress: .zero,
            hidden: true
        )
    }()
    
    var model: ChatFile = .default {
        didSet {
            guard oldValue != model else { return }
            update()
        }
    }
    
    var buttonActionHandler: (() -> Void)?
    
    init(model: ChatFile) {
        super.init(frame: .zero)
        backgroundColor = .clear
        configure()
        self.model = model
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconImageView.layer.cornerRadius = 5
    }
    
    @objc func tapBtnAction() {
        buttonActionHandler?()
    }
}

private extension ChatFileView {
    func configure() {
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(imageSize)
        }
        
        addSubview(additionalLabel)
        additionalLabel.snp.makeConstraints { make in
            make.center.equalTo(iconImageView.snp.center)
        }
        
        addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalTo(iconImageView)
            make.size.equalTo(imageSize / 2)
        }
        
        addSubview(downloadImageView)
        downloadImageView.snp.makeConstraints { make in
            make.center.equalTo(iconImageView)
            make.size.equalTo(imageSize / 1.3)
        }
        
        addSubview(videoIconIV)
        videoIconIV.snp.makeConstraints { make in
            make.center.equalTo(iconImageView)
            make.size.equalTo(imageSize / 2)
        }
        
        addSubview(previewDownloadNotAllowedLabel)
        previewDownloadNotAllowedLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView.snp.centerY)
            make.horizontalEdges.equalTo(iconImageView).inset(5)
        }
        
        addSubview(tapBtn)
        tapBtn.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        previewDownloadNotAllowedLabel.text = previewDownloadNotAllowedText
        previewDownloadNotAllowedLabel.numberOfLines = .zero
        previewDownloadNotAllowedLabel.textAlignment = .center
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.textAlignment = .left
        sizeLabel.textAlignment = .left
        iconImageView.layer.cornerRadius = 5
        iconImageView.layer.masksToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        additionalLabel.textAlignment = .center        
        videoIconIV.tintColor = .adamant.active
        
        videoIconIV.addShadow()
        downloadImageView.addShadow()
        spinner.addShadow(shadowColor: .white)
        previewDownloadNotAllowedLabel.addShadow()
    }
    
    func update() {
        let image: UIImage?
        if let previewImage = model.previewImage {
            image = previewImage
            additionalLabel.isHidden = true
            previewDownloadNotAllowedLabel.isHidden = true
        } else {
            image = model.fileType == .image || model.fileType == .video 
            ? defaultMediaImage
            : defaultImage
            
            previewDownloadNotAllowedLabel.isHidden = model.isPreviewDownloadAllowed
            || model.isBusy
            || !(model.fileType == .image || model.fileType == .video)
            
            additionalLabel.isHidden = !previewDownloadNotAllowedLabel.isHidden
        }
        
        if iconImageView.image != image {
            iconImageView.image = image
        }
        
        downloadImageView.isHidden = model.isCached || model.isBusy
        
        if model.isBusy {
            spinner.startAnimating()
            progressState.hidden = false
            progressState.progress = Double(model.progress) / 100
        } else {
            spinner.stopAnimating()
            progressState.hidden = true
            progressState.progress = .zero
        }
        
        let fileType = model.file.type.map { ".\($0)" } ?? .empty
        let fileName = model.file.name ?? "UNKNWON"
        
        nameLabel.text = fileName.contains(fileType)
        ? fileName
        : "\(fileName.uppercased())\(fileType.uppercased())"
        
        sizeLabel.text = formatSize(model.file.size)
        additionalLabel.text = fileType.uppercased()
        
        videoIconIV.isHidden = !(
            model.isCached
            && !model.isBusy
            && model.fileType == .video
        )
    }
    
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.countStyle = .file

        return formatter.string(fromByteCount: bytes)
    }
}

private let additionalFont = UIFont.boldSystemFont(ofSize: 15)
private let nameFont = UIFont.systemFont(ofSize: 15)
private let sizeFont = UIFont.systemFont(ofSize: 13)
private let imageSize: CGFloat = 70
private let stackSpacing: CGFloat = 12
private let verticalStackSpacing: CGFloat = 3
private let defaultImage: UIImage? = .asset(named: "defaultFileIcon")
private let defaultMediaImage: UIImage? = .asset(named: "defaultMediaBlur")
private let previewDownloadNotAllowedFont = UIFont.systemFont(ofSize: 6)
private var previewDownloadNotAllowedText: String { .localized("Chats.AutoDownloadPreview.Disabled") }
