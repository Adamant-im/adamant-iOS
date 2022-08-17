//
//  CheckmarkView.swift
//  Adamant
//
//  Created by Andrey on 13.06.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class CheckmarkView: UIView {
    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }
    
    var onCheckmarkTap: (() -> Void)?
    private(set) var isChecked = false
    private(set) var isUpdating = false
    
    var imageBorderColor: CGColor? {
        get { imageBackgroundView.layer.borderColor }
        set { imageBackgroundView.layer.borderColor = newValue }
    }
    
    var imageTintColor: UIColor? {
        get { imageView.tintColor }
        set { imageView.tintColor = newValue }
    }
    
    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.isHidden = true
        return view
    }()
    
    private lazy var imageBackgroundView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = checkmarkSize / 2
        view.layer.borderColor = UIColor.adamant.secondary.cgColor
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.tintColor = .adamant.primary
        return view
    }()
    
    private lazy var checkmarkContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateImage(animated: false)
    }
    
    func setIsChecked(_ isChecked: Bool, animated: Bool) {
        self.isChecked = isChecked
        updateImage(animated: animated)
    }
    
    func setIsUpdating(_ isUpdating: Bool, animated: Bool) {
        self.isUpdating = isUpdating
        if isUpdating {
            imageBackgroundView.alpha = .zero
            spinner.isHidden = false
            startAnimating()
        } else {
            imageBackgroundView.alpha = 1.0
            spinner.isHidden = true
            stopAnimating()
        }
    }
    
    private func setupView() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        
        addSubview(checkmarkContainer)
        checkmarkContainer.snp.makeConstraints {
            $0.size.equalTo(checkmarkSize)
            $0.center.equalToSuperview()
        }
        
        checkmarkContainer.addSubview(imageBackgroundView)
        imageBackgroundView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        checkmarkContainer.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        checkmarkContainer.addSubview(spinner)
        spinner.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    @objc private func onTap() {
        onCheckmarkTap?()
    }
    
    private func updateImage(animated: Bool) {
        if isChecked {
            showImage(animated: animated)
        } else {
            hideImage(animated: animated)
        }
    }
    
    private func showImage(animated: Bool) {
        imageView.isHidden = false
        
        guard animated else {
            imageView.transform = CGAffineTransform.identity
            return
        }
        
        UIView.animate(
            withDuration: 0.15,
            delay: .zero,
            options: [.allowAnimatedContent],
            animations: { [self] in
                imageView.transform = CGAffineTransform.identity
                imageBackgroundView.alpha = .zero
            }
        )
    }
    
    private func hideImage(animated: Bool) {
        guard animated else {
            imageView.isHidden = true
            imageView.transform = CGAffineTransform(scaleX: .zero, y: .zero)
            return
        }
        
        UIView.animate(
            withDuration: 0.15,
            delay: .zero,
            options: [.allowAnimatedContent],
            animations: { [self] in
                imageView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                imageBackgroundView.alpha = 1
            },
            completion: { [self] _ in
                guard !isChecked else { return }
                imageView.transform = CGAffineTransform(scaleX: .zero, y: .zero)
                imageView.isHidden = true
            }
        )
    }
    
    private func startAnimating() {
        spinner.startAnimating()
    }
    
    private func stopAnimating() {
        spinner.stopAnimating()
    }
}

private let checkmarkSize: CGFloat = 24
