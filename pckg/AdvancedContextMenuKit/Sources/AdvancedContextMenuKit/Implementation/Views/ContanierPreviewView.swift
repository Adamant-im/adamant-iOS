//
//  ContanierPreviewView.swift
//  
//
//  Created by Stanislav Jelezoglo on 04.08.2023.
//

import UIKit

final class ContanierPreviewView: UIView {
    private let contentView: UIView
    private let animationInDuration: TimeInterval
    
    init(
        contentView: UIView,
        scale: CGFloat,
        size: CGSize,
        animationInDuration: TimeInterval
    ) {
        self.animationInDuration = animationInDuration
        self.contentView = contentView
        
        super.init(
            frame: .init(
                origin: .zero,
                size: .init(
                    width: size.width,
                    height: size.height
                )
            )
        )
        
        self.contentView.frame.origin.x = .zero
        self.contentView.transform = .init(scaleX: scale, y: scale)
        self.contentView.widthAnchor.constraint(
            lessThanOrEqualToConstant: size.width
        ).isActive = true
        
        backgroundColor = .clear
        addSubview(self.contentView)
        
        self.contentView.center.y = center.y
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.center.y = center.y
        
        UIView.animate(withDuration: animationInDuration) {
            self.contentView.transform = .identity
        }
    }
}
