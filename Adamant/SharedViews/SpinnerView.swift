//
//  SpinnerView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 02.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import SnapKit
import UIKit

final class SpinnerView: UIView {
    static let size = CGSize(squareSize: 50)

    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    func startAnimating() {
        spinner.isHidden = false
        spinner.startAnimating()
    }

    func stopAnimating() {
        spinner.isHidden = true
        spinner.stopAnimating()
    }
}

extension SpinnerView: ReusableView {
    func prepareForReuse() {
        stopAnimating()
    }
}

extension SpinnerView {
    fileprivate func configure() {
        addSubview(spinner)
        spinner.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
