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
        collection: MessagesCollectionView
    ) {
        // TODO: Figure out why 'removeDuplicates()' is not enough
        subscription = publisher
            .removeDuplicates()
            .sink { [weak self, weak collection] newModel in
                guard newModel != self?.model else { return }
                
                self?.model = newModel
                collection?.collectionViewLayout.invalidateLayout()
            }
    }
    
    func prepareForReuse() {
        model = .default
        actionHandler = { _ in }
        subscription = nil
    }
}
