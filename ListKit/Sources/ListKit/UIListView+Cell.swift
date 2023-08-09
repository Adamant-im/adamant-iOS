//
//  UIListView+Cell.swift
//  
//
//  Created by Andrey Golubenko on 09.08.2023.
//

import UIKit
import Combine

public extension UIListView {
    final class Cell<View: UIListItemView>: UICollectionViewCell {
        let wrappedView = View()
        var subscription: AnyCancellable?
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            configure()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }
        
        public override func layoutSubviews() {
            super.layoutSubviews()
            wrappedView.frame = contentView.bounds
        }
    }
}

extension UIListView.Cell {
    func subscribe<P: Publisher<View.Model, Never>>(
        publisher: P,
        collectionViewLayout: UICollectionViewLayout
    ) {
        subscription = publisher.sink { [weak wrappedView, collectionViewLayout] newModel in
            guard
                let oldModel = wrappedView?.model,
                newModel != oldModel
            else { return }
            
            wrappedView?.model = newModel
            let width = collectionViewLayout.collectionViewContentSize.width
            
            guard newModel.height(width: width) != oldModel.height(width: width) else { return }
            collectionViewLayout.invalidateLayout()
        }
    }
}

private extension UIListView.Cell {
    func configure() {
        contentView.addSubview(wrappedView)
    }
}
