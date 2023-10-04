//
//  ChatLoaderView.swift
//
//
//  Created by Andrew G on 03.10.2023.
//

import UIKit
import CommonKit

final class ChatLoaderView: UIView {
    private let loader = UIActivityIndicatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension ChatLoaderView: ReusableView {
    func prepareForReuse() {}
}

private extension ChatLoaderView {
    func configure() {
        addSubview(loader)
        loader.snp.makeConstraints {
            $0.directionalVerticalEdges.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
        }
        
        loader.startAnimating()
    }
}
