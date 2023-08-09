//
//  UIListView+FlowLayout.swift
//  
//
//  Created by Andrey Golubenko on 09.08.2023.
//

import UIKit

extension UIListView {
    open class FlowLayout: UICollectionViewFlowLayout {
        override public init() {
            super.init()
            setup()
        }
        
        public required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }
    }
}

private extension UIListView.FlowLayout {
    func setup() {
        scrollDirection = .vertical
        minimumLineSpacing = .leastNormalMagnitude
    }
}
