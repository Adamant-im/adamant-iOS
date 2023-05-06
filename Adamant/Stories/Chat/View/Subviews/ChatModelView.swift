//
//  ChatModelView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import Combine

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
    func setSubscription<P: Observable<Model>>(publisher: P) {
        subscription = publisher
            .removeDuplicates()
            .sink { [weak self] in self?.model = $0 }
    }
    
    func prepareForReuse() {
        model = .default
        actionHandler = { _ in }
        subscription = nil
    }
}
