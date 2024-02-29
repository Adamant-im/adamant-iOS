//
//  ChatFileTableViewCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit

class ChatFileTableViewCell: UITableViewCell {
    private lazy var iconImageView: UIImageView = UIImageView()
    private lazy var downloadImageView = UIImageView(image: .asset(named: "downloadIcon"))
    
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
    private let sizeLabel = UILabel(font: sizeFont, textColor: .adamant.textColor)
    
    private lazy var vStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = stackSpacing
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = nil
        contentView.backgroundColor = nil
        
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func tapBtnAction() {
        buttonActionHandler?()
    }
}

private extension ChatFileTableViewCell {
    func configure() {
        contentView.addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(imageSize)
        }
        
        contentView.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalTo(iconImageView)
        }
        
        contentView.addSubview(downloadImageView)
        downloadImageView.snp.makeConstraints { make in
            make.center.equalTo(iconImageView)
            make.size.equalTo(imageSize / 1.3)
        }
        
        contentView.addSubview(tapBtn)
        tapBtn.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.textAlignment = .left
        sizeLabel.textAlignment = .left
        iconImageView.layer.cornerRadius = 5
        iconImageView.layer.masksToBounds = true
        iconImageView.contentMode = .scaleAspectFill
    }
    
    func update() {
        iconImageView.image = model.previewData
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
        sizeLabel.text = "\(model.file.file_size) kb"
    }
}

private let nameFont = UIFont.systemFont(ofSize: 15)
private let sizeFont = UIFont.systemFont(ofSize: 13)
private let imageSize: CGFloat = 70
private let stackSpacing: CGFloat = 12
