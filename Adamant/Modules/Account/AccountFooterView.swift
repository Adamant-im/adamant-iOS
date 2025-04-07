//
//  AccountFooterView.swift
//  Adamant
//
//  Created by Yana Silosieva on 18.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import SnapKit
import UIKit

final class AccountFooterView: UIView {
    private let footerImageview = UIImageView(image: UIImage.asset(named: "avatar_bots"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(footerImageview)

        footerImageview.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.top.centerX.equalToSuperview()
        }
    }
}
