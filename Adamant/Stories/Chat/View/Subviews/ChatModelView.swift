//
//  ChatModelView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import Combine
import MessageKit

protocol ChatReusableViewModelProtocol: Equatable {
    static var `default`: Self { get }
    
    func height(
        for width: CGFloat,
        indexPath: IndexPath,
        calculator: TextMessageSizeCalculator
    ) -> CGFloat
}

struct ChatReusableViewModelSizeDeps {
    let layout: MessagesLayoutDelegate
    let defaultTextMessageSize: () -> CGSize
}

protocol ChatModelView: UIView, ReusableView {
    associatedtype Model: ChatReusableViewModelProtocol
    
    var model: Model { get set }
    var actionHandler: (ChatAction) -> Void { get set }
    var subscription: AnyCancellable? { get set }
}

extension ChatModelView {
    func setSubscription<P: Observable<Model>>(
        publisher: P,
        collection: MessagesCollectionView,
        indexPath: IndexPath
    ) {
        subscription = publisher
            .removeDuplicates()
            .sink { [weak self, weak collection] newModel in
                guard
                    let self = self,
                    let collection = collection
                else { return }
                
                defer { self.model = newModel }
                
                guard
                    self.checkIsNeededToUpdateLayout(
                        indexPath: indexPath,
                        oldModel: self.model,
                        newModel: newModel,
                        flowLayout: collection.messagesCollectionViewFlowLayout
                    )
                else { return }
                
                collection.collectionViewLayout.invalidateLayout()
            }
    }
    
    func prepareForReuse() {
        model = .default
        actionHandler = { _ in }
        subscription = nil
    }
}

private extension ChatModelView {
    func checkIsNeededToUpdateLayout(
        indexPath: IndexPath,
        oldModel: Model,
        newModel: Model,
        flowLayout: MessagesCollectionViewFlowLayout
    ) -> Bool {
        let calculator = TextMessageSizeCalculator(layout: flowLayout)
        
        let oldHeight = oldModel.height(
            for: flowLayout.itemWidth,
            indexPath: indexPath,
            calculator: calculator
        )
        
        let newHeight = newModel.height(
            for: flowLayout.itemWidth,
            indexPath: indexPath,
            calculator: calculator
        )
        
        return oldHeight != newHeight
    }
}
