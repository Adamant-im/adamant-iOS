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
    
    private lazy var imageView = UIImageView(image: nil)
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.font = titleType.font
        return label
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.isHidden = true
        view.color = .adamant.textColor
        return view
    }()
    
    private lazy var userDataStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 5
        stackView.alignment = .center

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)

        imageView.snp.makeConstraints { make in
            make.size.equalTo(imageSize)
        }

        return stackView
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
    private var image: UIImage? {
        didSet {
            updateImageViewSize()
        }
    }
    
    private var imageSize: CGFloat {
        image != nil ? 25 : .zero
    }
    
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
        addSubview(userDataStackView)
        addSubview(spinner)
        
        userDataStackView.snp.makeConstraints { make in
            make.centerY.leading.trailing.equalToSuperview()
        }
        spinner.snp.makeConstraints { make in
            make.trailing.equalTo(titleLabel.snp.leading).offset(-5)
            make.centerY.equalToSuperview()
        }
    }
    
    @MainActor
    private func updateImageViewSize() {
        imageView.snp.updateConstraints { make in
            make.size.equalTo(imageSize)
        }
    }
    
    // MARK: Actions
    
    func startAnimate() {
        imageView.alpha = 0
        spinner.startAnimating()
    }
    
    func stopAnimate() {
        spinner.stopAnimating()
        imageView.alpha = 1
    }
    
    func updateTitle(title: String?) {
        self.title = title ?? ""
        titleLabel.text = title
    }
    
    func updateImage(image: UIImage?) {
        self.image = image
        imageView.image = image
    }
}
