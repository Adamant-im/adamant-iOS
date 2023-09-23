//
//  LoadingView.swift
//  Adamant
//
//  Created by Andrey on 30.07.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import CommonKit

final class LoadingView: UIView {
    private let logo = UIImageView(image: .asset(named: "Adamant-logo"))
    private let spinner = UIActivityIndicatorView(style: .whiteLarge)
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func startAnimating() {
        spinner.startAnimating()
    }
    
    func stopAnimating() {
        spinner.stopAnimating()
    }
    
    private func setupView() {
        backgroundColor = .adamant.background
        
        addSubview(logo)
        logo.snp.makeConstraints {
            $0.size.equalTo(100)
            $0.center.equalToSuperview()
        }
        
        addSubview(spinner)
        spinner.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
