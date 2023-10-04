//
//  ChatDateView.swift
//  
//
//  Created by Andrew G on 03.10.2023.
//

import UIKit
import CommonKit

final class ChatDateView: UIView, Modelable {
    var modelStorage: String = .empty {
        didSet { update() }
    }
    
    private let label = UILabel(
        font: .boldSystemFont(ofSize: 10),
        textColor: .adamant.primary,
        numberOfLines: 1,
        textAlignment: .center
    )
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension ChatDateView: ReusableView {
    func prepareForReuse() {}
}

private extension ChatDateView {
    func configure() {
        addSubview(label)
        label.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview().inset(8)
        }
        
        update()
    }
    
    func update() {
        label.text = model
    }
}
