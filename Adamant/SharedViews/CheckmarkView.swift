//
//  CheckmarkView.swift
//  Adamant
//
//  Created by Andrey on 13.06.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit

final class CheckmarkView: UIView {
    var borderColor: UIColor? {
        get { imageBackgroundView.layer.borderColor.map { UIColor(cgColor: $0) } }
        set { imageBackgroundView.layer.borderColor = newValue?.cgColor }
    }
    
    var imageColor: UIColor {
        get { imageView.tintColor }
        set { imageView.tintColor = newValue }
    }
    
    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }
    
    var onCheckmarkTap: (() -> Void)?
    private(set) var isChecked = false
    
    private lazy var imageBackgroundView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = checkmarkSize / 2
        return view
    }()
    
    private lazy var imageView = UIImageView()
    private lazy var checkmarkContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        checkmarkContainer.frame = CGRect(
            x: (bounds.width - checkmarkSize) / 2,
            y: (bounds.height - checkmarkSize) / 2,
            width: checkmarkSize,
            height: checkmarkSize
        )
        
        imageBackgroundView.frame = checkmarkContainer.bounds
        imageView.frame = checkmarkContainer.bounds
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateImage(animated: false)
    }
    
    func setIsChecked(_ isChecked: Bool, animated: Bool) {
        guard self.isChecked != isChecked else { return }
        
        self.isChecked = isChecked
        updateImage(animated: animated)
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(checkmarkContainer)
        checkmarkContainer.addSubview(imageBackgroundView)
        checkmarkContainer.addSubview(imageView)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
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
                guard isChecked else { return }
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
                guard !isChecked else { return }
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
}

private let checkmarkSize: CGFloat = 24
