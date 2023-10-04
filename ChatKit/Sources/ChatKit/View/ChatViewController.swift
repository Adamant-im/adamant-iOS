//
//  ChatViewController.swift
//  
//
//  Created by Andrew G on 03.10.2023.
//

import UIKit
import SnapKit
import CommonKit

open class ChatViewController: UIViewController, Modelable {
    public var modelStorage: ChatState = .default {
        didSet { update() }
    }
    
    private lazy var chatCollectionView = ChatCollectionView()
    
    override public init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
        configure()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension ChatViewController {
    func configure() {
        view.addSubview(chatCollectionView)
        chatCollectionView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    func update() {
        chatCollectionView.model = model.items.wrappedByHashableId()
    }
}
