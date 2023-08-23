//
//  ContanierPreviewView.swift
//  
//
//  Created by Stanislav Jelezoglo on 04.08.2023.
//

import UIKit
import SnapKit

@MainActor
final class ContanierPreviewView: UIView {
    private let contentView: UIView
    private let animationInDuration: TimeInterval
    private let _size: CGSize
    
    override var intrinsicContentSize: CGSize {
        _size
    }
    
    init(
        contentView: UIView,
        scale: CGFloat,
        size: CGSize,
        animationInDuration: TimeInterval
    ) {
        self.animationInDuration = animationInDuration
        self.contentView = contentView
        self._size = size
        super.init(frame: .zero)
        self.contentView.clipsToBounds = true
        self.contentView.transform = .init(scaleX: scale, y: scale)
        
        backgroundColor = .clear
        addSubview(self.contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = .init(origin: .zero, size: intrinsicContentSize)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        UIView.animate(withDuration: animationInDuration) {
            self.contentView.transform = .identity
        }
    }
}
