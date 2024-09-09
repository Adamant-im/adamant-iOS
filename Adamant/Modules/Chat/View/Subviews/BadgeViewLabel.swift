//
//  BadgeView.swift
//  Adamant
//
//  Created by Аркадий Торвальдс on 26.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

final class BadgeViewLabel: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
    
    @MainActor
    func updateCounter(count: Int) {
        isHidden = count == 0
        let formatText: String = count > 99 ? "99+" : "\(count)"
        text = formatText
    }
}

private extension BadgeViewLabel {
    func configure() {
        isHidden = true
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        backgroundColor = .systemRed
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        textAlignment = .center
        font = .systemFont(ofSize: fontSize)
        textColor = .white
        text = .empty
        translatesAutoresizingMaskIntoConstraints = false
        self.snp.makeConstraints { make in
            make.height.equalTo(size)
            make.width.greaterThanOrEqualTo(size)
        }
    }
}

private let size: CGFloat = 16
private let textInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
private let cornerRadius: CGFloat = 8
private let fontSize: CGFloat = 12
