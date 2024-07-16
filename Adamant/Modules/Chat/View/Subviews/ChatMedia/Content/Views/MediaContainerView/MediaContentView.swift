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
import SwiftUI

final class MediaContentView: UIView {
    private lazy var imageView: UIImageView = UIImageView()
    private lazy var downloadImageView = UIImageView(image: .asset(named: "downloadIcon"))
    private lazy var videoIconIV = UIImageView(image: .asset(named: "playVideoIcon"))
    
    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.isHidden = true
        view.color = .white
        view.backgroundColor = .darkGray.withAlphaComponent(0.45)
        return view
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
            make.size.equalTo(imageSize / 2)
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
        
        let controller = UIHostingController(rootView: progressBar.environmentObject(progressState))
        
        controller.view.backgroundColor = .clear
        addSubview(controller.view)
        controller.view.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(15)
            make.size.equalTo(15)
        }
        
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        videoIconIV.tintColor = .adamant.active
        
        videoIconIV.addShadow()
        downloadImageView.addShadow()
        spinner.addShadow(shadowColor: .white)
        controller.view.addShadow()
    }
    
    func update() {
        let image = model.previewImage ?? defaultMediaImage

        if imageView.image != image {
            imageView.image = image
        }
        
        downloadImageView.isHidden = model.isCached || model.isBusy
        
        videoIconIV.isHidden = !(
            model.isCached
            && !model.isBusy
            && model.fileType == .video
        )
        
        if model.isDownloading {
            if model.previewImage == nil || !model.isFullMediaDownloadAllowed {
                spinner.startAnimating()
            } else {
                spinner.stopAnimating()
            }
        } else {
            spinner.stopAnimating()
        }
        
        if model.isBusy {
            if model.isUploading {
                progressState.hidden = false
            } else {
                progressState.hidden = !model.isFullMediaDownloadAllowed
            }
            
            progressState.progress = Double(model.progress) / 100
        } else {
            progressState.hidden = true
            progressState.progress = .zero
        }
    }
}

private let imageSize: CGFloat = 70
private let stackSpacing: CGFloat = 12
private let verticalStackSpacing: CGFloat = 3
private let defaultImage: UIImage? = .asset(named: "defaultFileIcon")
private let defaultMediaImage: UIImage? = .asset(named: "defaultMediaBlur")
