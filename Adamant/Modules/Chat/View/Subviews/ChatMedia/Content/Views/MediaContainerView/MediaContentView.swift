//
//  MediaContentView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

final class MediaContentView: UIView {
    private lazy var imageView: UIImageView = UIImageView()
    private lazy var downloadImageView = UIImageView(image: .asset(named: "downloadIcon"))
    
    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.isHidden = true
        view.color = .black
        return view
    }()
    
    private lazy var tapBtn: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(tapBtnAction), for: .touchUpInside)
        return btn
    }()
    
    var model: ChatFile = .default {
        didSet {
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
        
        imageView.layer.cornerRadius = 5
    }
    
    @objc func tapBtnAction() {
        buttonActionHandler?()
    }
}

private extension MediaContentView {
    func configure() {
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalTo(imageView)
        }
        
        addSubview(downloadImageView)
        downloadImageView.snp.makeConstraints { make in
            make.center.equalTo(imageView)
            make.size.equalTo(imageSize / 1.3)
        }
        
        addSubview(tapBtn)
        tapBtn.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        imageView.layer.cornerRadius = 5
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
    }
    
    func update() {
        if let url = model.previewDataURL {
            imageView.image = UIImage(contentsOfFile: url.path)
        } else {
            imageView.image = defaultImage
        }
        
        downloadImageView.isHidden = model.isCached || model.isDownloading || model.isUploading
        
        if model.isDownloading || model.isUploading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }
}

private let imageSize: CGFloat = 70
private let stackSpacing: CGFloat = 12
private let verticalStackSpacing: CGFloat = 3
private let defaultImage: UIImage? = .asset(named: "file-default-box")
