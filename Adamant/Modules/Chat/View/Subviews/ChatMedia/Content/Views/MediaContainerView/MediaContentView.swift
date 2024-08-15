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
    
    private lazy var progressBar = CircularProgressView(state: progressState)
    private lazy var progressState: CircularProgressState = {
        .init(
            lineWidth: 2.0,
            backgroundColor: .lightGray,
            progressColor: .white,
            progress: .zero,
            hidden: true
        )
    }()
    
    private lazy var durationLabel = EdgeInsetLabel(
        font: durationFont,
        textColor: .white.withAlphaComponent(0.8)
    )
    
    var model: ChatMediaContentView.FileContentModel = .default {
        didSet {
            update()
        }
    }
    
    var buttonActionHandler: (() -> Void)?
    
    init(model: ChatMediaContentView.FileContentModel) {
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
        
        addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().offset(-10)
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
        
        let controller = UIHostingController(rootView: progressBar)
        
        controller.view.backgroundColor = .clear
        addSubview(controller.view)
        controller.view.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(15)
            make.size.equalTo(progressSize)
        }
        
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        videoIconIV.tintColor = .adamant.active
        
        videoIconIV.addShadow()
        downloadImageView.addShadow()
        spinner.addShadow(shadowColor: .white)
        controller.view.addShadow()
        
        durationLabel.textInsets = durationTextInsets
        durationLabel.numberOfLines = .zero
        durationLabel.textAlignment = .center
        durationLabel.backgroundColor = .black.withAlphaComponent(0.1)
        durationLabel.layer.cornerRadius = 6
        durationLabel.addShadow()
        durationLabel.clipsToBounds = true
    }
    
    func update() {
        let chatFile = model.chatFile
        
        let image = chatFile.previewImage ?? defaultMediaImage
        
        if imageView.image != image {
            imageView.image = image
        }
        
        downloadImageView.isHidden = chatFile.isCached
        || chatFile.isBusy
        || model.txStatus == .failed
        || chatFile.previewImage == nil
        
        videoIconIV.isHidden = !(
            chatFile.isCached
            && !chatFile.isBusy
            && chatFile.fileType == .video
        )
        
        if chatFile.isDownloading {
            if chatFile.previewImage == nil,
               chatFile.file.preview != nil,
               chatFile.downloadStatus.isPreviewDownloading {
                spinner.startAnimating()
            } else {
                spinner.stopAnimating()
            }
        } else {
            spinner.stopAnimating()
        }
        
        if chatFile.isBusy {
            if chatFile.isUploading {
                progressState.hidden = false
            } else {
                progressState.hidden = !chatFile.downloadStatus.isOriginalDownloading
            }
        } else {
            progressState.hidden = chatFile.progress == 100
            || chatFile.progress == nil
        }
        
        let progress = chatFile.progress ?? .zero
        progressState.progress = Double(progress) / 100
        
        durationLabel.isHidden = chatFile.fileType != .video
        
        if let duration = chatFile.file.duration {
            durationLabel.text = formatTime(seconds: Int(duration))
        } else {
            durationLabel.text = "-:-"
        }
    }
    
    func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

private let imageSize: CGFloat = 70
private let progressSize: CGFloat = 15
private let stackSpacing: CGFloat = 12
private let verticalStackSpacing: CGFloat = 3
private let defaultImage: UIImage? = .asset(named: "defaultFileIcon")
private let defaultMediaImage: UIImage? = .asset(named: "defaultMediaBlur")
private let durationFont = UIFont.systemFont(ofSize: 10)
private let durationTextInsets: UIEdgeInsets = .init(top: 3, left: 3, bottom: 3, right: 3)
