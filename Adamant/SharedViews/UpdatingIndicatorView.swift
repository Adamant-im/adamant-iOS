//
//  UpdatingIndicatorView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 17.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class UpdatingIndicatorView: UIView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .title3)
        return label
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.isHidden = true
        view.color = .adamant.textColor
        return view
    }()
    
    // MARK: Proprieties
    
    private var title: String
    
    // MARK: Init
    
    init(title: String) {
        self.title = title
        super.init(frame: .zero)

        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.title = ""
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(titleLabel)
        addSubview(spinner)
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
        }
        spinner.snp.makeConstraints { make in
            make.trailing.equalTo(titleLabel.snp.leading).offset(-5)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: Actions
    
    func startAnimate() {
        spinner.startAnimating()
    }
    
    func stopAnimate() {
        spinner.stopAnimating()
    }
    
}
