//
//  CommonPreviewView.swift
//  
//
//  Created by Stanislav Jelezoglo on 26.06.2023.
//

import UIKit

final class CommonPreviewView: UIView {
    private let contentView: UIView
    
    init(contentView: UIView, x: CGFloat) {
        self.contentView = contentView.snapshotView(afterScreenUpdates: true) ?? contentView
        self.contentView.frame.origin.x = x
        
        super.init(
            frame: .init(
                origin: .zero,
                size: .init(
                    width: contentView.superview?.frame.width ?? .infinity,
                    height: self.contentView.frame.height
                )
            )
        )
        
        self.contentView.transform = .init(scaleX: 0.9, y: 0.9)
        
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
        
        UIView.animate(withDuration: 0.29) {
            self.contentView.transform = .identity
        }
    }
}
