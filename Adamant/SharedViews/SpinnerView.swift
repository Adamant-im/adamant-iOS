//
//  SpinnerView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 02.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

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
        spinner.startAnimating()
    }

    func stopAnimating() {
        spinner.stopAnimating()
    }
}

extension SpinnerView: ReusableView {
    func prepareForReuse() {
        stopAnimating()
    }
}

private extension SpinnerView {
    func configure() {
        addSubview(spinner)
        spinner.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
