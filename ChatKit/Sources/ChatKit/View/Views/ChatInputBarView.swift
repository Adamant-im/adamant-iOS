//
//  ChatInputBarView.swift
//  
//
//  Created by Andrew G on 03.10.2023.
//

import UIKit
import CommonKit

final class ChatInputBarView: UIView, Modelable {
    var modelStorage: ChatInputBarModel = .default {
        didSet { update() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension ChatInputBarView {
    func configure() {
        update()
    }
    
    func update() {
        
    }
}
