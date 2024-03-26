//
//  ChatFileTableViewCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit

class ChatFileView: UIView {
    private lazy var iconImageView: UIImageView = UIImageView()
    private lazy var downloadImageView = UIImageView(image: .asset(named: "downloadIcon"))
    private lazy var videoIconIV = UIImageView(image: .init(systemName: "play.circle"))

    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.isHidden = true
        view.color = .black
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

    private lazy var vStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = verticalStackSpacing
        stack.backgroundColor = .clear

        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(sizeLabel)
        return stack
    }()
    
    private lazy var tapBtn: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(tapBtnAction), for: .touchUpInside)
        return btn
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
        
        addSubview(tapBtn)
        tapBtn.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
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
    }
    
    func update() {
        if let url = model.previewDataURL {
            iconImageView.image = UIImage(contentsOfFile: url.path)
            additionalLabel.isHidden = true
        } else {
            additionalLabel.isHidden = false
            iconImageView.image = defaultImage
        }
        
        downloadImageView.isHidden = model.isCached || model.isDownloading || model.isUploading
        
        if model.isDownloading || model.isUploading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        
        let fileType = model.file.file_type ?? ""
        let fileName = model.file.file_name ?? "UNKNWON"
        
        nameLabel.text = fileName.contains(fileType)
        ? fileName
        : "\(fileName.uppercased()).\(fileType.uppercased())"
        
        sizeLabel.text = formatSize(model.file.file_size)
        additionalLabel.text = fileType.uppercased()
        
        videoIconIV.isHidden = !(model.isCached
        && !model.isDownloading
        && !model.isUploading
        && model.isVideo)
    }
    
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
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
private let defaultImage: UIImage? = .asset(named: "file-default-box")
