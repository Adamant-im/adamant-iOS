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
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        
        view.addSubview(imageView)
        view.addSubview(removeBtn)
        
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 5
        
        imageView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        removeBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-15)
            make.trailing.equalToSuperview().offset(15)
        }
        return view
    }()
    
    private lazy var removeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(
            UIImage(systemName: "xmark.app.fill")?.withTintColor(.adamant.alert),
            for: .normal
        )
        btn.addTarget(self, action: #selector(didTapRemoveBtn), for: .touchUpInside)
        
        btn.snp.makeConstraints { make in
            make.size.equalTo(40)
        }
        return btn
    }()
    
    var buttonActionHandler: ((Int) -> Void)?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
    }
    
    @objc private func didTapRemoveBtn() {
        buttonActionHandler?(removeBtn.tag)
    }
    
    func update(_ file: FileResult, tag: Int) {
        imageView.image = file.preview ?? defaultImage
        removeBtn.tag = tag
    }
}

private let defaultImage: UIImage? = .asset(named: "file-default-box")
