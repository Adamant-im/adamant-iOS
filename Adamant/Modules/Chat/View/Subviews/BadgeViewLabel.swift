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
    
    @MainActor
    func updateCounter(count: Int) {
        isHidden = count == 0
        let formatText: String = count > 99 ? "99+" : "\(count)"
        text = formatText
    }
}

private extension BadgeViewLabel {
    func configure() {
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
    }
}

private let cornerRadius: CGFloat = 8
private let fontSize: CGFloat = 12
