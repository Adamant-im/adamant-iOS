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
        let formatText = formatNumber(count)
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
    
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1

        switch number {
        case 1_000_000_000...:
            let formatted = formatter.string(from: NSNumber(value: Double(number) / 1_000_000_000)) ?? "\(number)"
            return "\(formatted)B"
        case 1_000_000...:
            let formatted = formatter.string(from: NSNumber(value: Double(number) / 1_000_000)) ?? "\(number)"
            return "\(formatted)M"
        case 1_000...:
            let formatted = formatter.string(from: NSNumber(value: Double(number) / 1_000)) ?? "\(number)"
            return "\(formatted)K"
        default:
            return "\(number)"
        }
    }
}

fileprivate let cornerRadius: CGFloat = 8
fileprivate let fontSize: CGFloat = 12
