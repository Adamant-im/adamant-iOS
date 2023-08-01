//
//  UpdatingIndicatorView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 17.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import CommonKit

final class UpdatingIndicatorView: UIView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.font = titleType.font
        return label
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.isHidden = true
        view.color = .adamant.textColor
        return view
    }()
    
    // MARK: Proprieties
    
    enum TitleType {
        case small
        case medium
        
        var font: UIFont {
            switch self {
            case .small: return .preferredFont(forTextStyle: .headline)
            case .medium: return .preferredFont(forTextStyle: .title3)
            }
        }
    }
    
    private var title: String
    private var titleType: TitleType
    
    // MARK: Init
    
    init(title: String, titleType: TitleType = .medium) {
        self.title = title
        self.titleType = titleType
        super.init(frame: .zero)

        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.title = ""
        self.titleType = .small
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
    
    func updateTitle(title: String?) {
        self.title = title ?? ""
        titleLabel.text = title
    }
}
