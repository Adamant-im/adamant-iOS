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

class BadgeView: UIView {
    private lazy var counterLabel: UILabel = {
        let rv = UILabel()
        rv.numberOfLines = 0
        rv.lineBreakMode = .byWordWrapping
        rv.font = .systemFont(ofSize: 12)
        rv.textColor = labelColor
        rv.text = String.empty
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()
    
    private var labelColor: UIColor {
        UIColor { traits -> UIColor in
            return traits.userInterfaceStyle == .dark ? UIColor.adamant.first : UIColor.adamant.fourth
        }
    }
    
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
        self.isHidden = count == 0
        let formatText = formatNumber(count)
        counterLabel.text = formatText
    }
}

private extension BadgeView {
    func configure() {
        backgroundColor = UIColor.adamant.primary
        layer.cornerRadius = 8
        addSubview(counterLabel)
        let padding: CGFloat = 4
        self.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(16)
        }
        counterLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualToSuperview().offset(padding)
            make.trailing.lessThanOrEqualToSuperview().offset(-padding)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
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
