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
    private lazy var videoIconIV = UIImageView(image: .asset(named: "playVideoIcon"))
    
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
        
        addSubview(videoIconIV)
        videoIconIV.snp.makeConstraints { make in
            make.center.equalTo(imageView)
            make.size.equalTo(imageSize / 1.6)
        }
        
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        videoIconIV.tintColor = .adamant.active

        videoIconIV.addShadow()
        downloadImageView.addShadow()
    }
    
    func update() {
        let image: UIImage?
        if let previewImage = model.previewImage {
            image = previewImage
        } else {
            image = model.fileType == .image || model.fileType == .video
            ? defaultMediaImage
            : defaultImage
        }
        
        if imageView.image != image {
            imageView.image = image
        }
        
        downloadImageView.isHidden = model.isCached || model.isDownloading || model.isUploading
        
        videoIconIV.isHidden = !(
            model.isCached
            && !model.isDownloading
            && !model.isUploading
            && model.fileType == .video
        )
        
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
private let defaultMediaImage: UIImage? = .asset(named: "file-image-box")
