//
//  FullscreenAlertView.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import CommonKit
import SafariServices
import SnapKit
import UIKit

final class FullscreenAlertView: UIView {
    var message: String = .empty {
        didSet { messageLabel.text = message }
    }
    
    var linkText: String? {
        didSet { 
            updateLinkLabel()
        }
    }
    
    var linkURL: URL? {
        didSet {
            updateLinkLabel()
        }
    }
    
    private let containerView: UIView = .init()
    private let imageView = UIImageView(image: warningImage)
    
    private let messageLabel = UILabel(
        font: .systemFont(ofSize: 15),
        textColor: .adamant.textColor,
        numberOfLines: .zero,
        alignment: .center
    )
    
    private lazy var linkLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .adamant.primary
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(linkTapped))
        label.addGestureRecognizer(tapGesture)
        
        return label
    }()
    
    private lazy var verticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [imageView, messageLabel, linkLabel])
        stack.axis = .vertical
        stack.spacing = 15
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension FullscreenAlertView {
    @objc func linkTapped() {
        guard let url = linkURL else { return }
        openURL(url)
    }
    
    func openURL(_ url: URL) {
        guard let viewController = findViewController() else { return }
        
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = .adamant.primary
        safari.modalPresentationStyle = .overFullScreen
        viewController.present(safari, animated: true, completion: nil)
    }
    
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
    
    func updateLinkLabel() {
        guard let text = linkText, !text.isEmpty else {
            linkLabel.isHidden = true
            return
        }
        
        linkLabel.isHidden = linkURL == nil
        
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.adamant.primary,
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ]
        )
        linkLabel.attributedText = attributedString
    }
}

extension FullscreenAlertView {
    fileprivate func configure() {
        backgroundColor = .black.withAlphaComponent(0.4)
        containerView.backgroundColor = .adamant.cellColor
        containerView.layer.cornerRadius = 15
        imageView.tintColor = .adamant.primary
        imageView.contentMode = .scaleAspectFit
        
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.leading.greaterThanOrEqualToSuperview().inset(15)
            $0.bottom.trailing.lessThanOrEqualToSuperview().inset(15)
        }
        
        containerView.addSubview(verticalStack)
        verticalStack.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview().inset(15)
        }
    }
}

private let warningImage = UIImage(
    systemName: "exclamationmark.triangle.fill",
    withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
)!
