//
//  FilesToolbarCollectionViewCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import FilesStorageKit
import CommonKit

final class FilesToolbarCollectionViewCell: UICollectionViewCell {
    private lazy var imageView = UIImageView(image: .init(systemName: "shareplay"))
    private lazy var videoIconIV = UIImageView(image: .asset(named: "playVideoIcon"))
    private lazy var nameLabel = UILabel(font: nameFont, textColor: .adamant.textColor)
    private let additionalLabel = UILabel(font: additionalFont, textColor: .adamant.cellColor)

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 5
        
        view.addSubview(imageView)
        view.addSubview(nameLabel)
        view.addSubview(additionalLabel)
        view.addSubview(videoIconIV)
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(nameLabel.snp.top).offset(-7)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(5)
            make.bottom.equalToSuperview().offset(-7)
            make.height.equalTo(17)
        }
        
        additionalLabel.snp.makeConstraints { make in
            make.center.equalTo(imageView.snp.center)
        }
        
        videoIconIV.snp.makeConstraints { make in
            make.center.equalTo(imageView.snp.center)
            make.size.equalTo(30)
        }
        
        return view
    }()
    
    private lazy var removeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(.asset(named: "checkMarkIcon"), for: .normal)
        btn.tintColor = .adamant.active
        btn.addTarget(self, action: #selector(didTapRemoveBtn), for: .touchUpInside)
        return btn
    }()
    
    var buttonActionHandler: ((Int) -> Void)?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didTapRemoveBtn() {
        buttonActionHandler?(removeBtn.tag)
    }
    
    func update(_ file: FileResult, tag: Int) {
        imageView.image = file.preview ?? defaultImage
        removeBtn.tag = tag
        
        let fileType = file.extenstion ?? ""
        let fileName = file.name ?? "UNKNWON"
        
        nameLabel.text = fileName.contains(fileType)
        ? fileName
        : "\(fileName.uppercased()).\(fileType.uppercased())"
        
        additionalLabel.text = fileType.uppercased()
        additionalLabel.isHidden = file.preview != nil
        
        videoIconIV.isHidden = file.type != .video
        layoutConstraints(file)
    }
}

private extension FilesToolbarCollectionViewCell {
    func configure() {
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview().inset(5)
        }
        
        addSubview(removeBtn)
        removeBtn.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.top).offset(1)
            make.trailing.equalTo(containerView.snp.trailing).offset(-1)
            make.size.equalTo(25)
        }
        
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        nameLabel.textAlignment = .center
        nameLabel.lineBreakMode = .byTruncatingMiddle
        
        removeBtn.addShadow()
        
        videoIconIV.tintColor = .adamant.active
        videoIconIV.addShadow()
    }
    
    func layoutConstraints(_ file: FileResult) {
        if file.preview == nil {
            imageView.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(10)
                make.bottom.equalTo(nameLabel.snp.top).offset(-7)
            }
            return
        }
        
        imageView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(nameLabel.snp.top).offset(-7)
        }
    }
}

private let defaultImage: UIImage? = .asset(named: "defaultFileIcon")
private let nameFont = UIFont.systemFont(ofSize: 13)
private let additionalFont = UIFont.boldSystemFont(ofSize: 15)
