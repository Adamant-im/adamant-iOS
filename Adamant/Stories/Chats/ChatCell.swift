//
//  ChatCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit

protocol ChatCell: AnyObject {
//    var bubbleStyle: MessageStyle { get set }
    var bubbleBackgroundColor: UIColor? { get set }
}

extension TransferCollectionViewCell {
    @objc func remove(_ sender: Any?) {
        trigger(action: "remove:", with: sender)
    }
    
    @objc func report(_ sender: Any?) {
        trigger(action: "report:", with: sender)
    }
    
    func trigger(action: String, with sender: Any?) {
        if let collectionView = self.superview as? UICollectionView {
            if let indexPath = collectionView.indexPath(for: self) {
                collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString(action), forItemAt: indexPath, withSender: sender)
            }
        }
    }
}

extension MessageCollectionViewCell {
    @objc func remove(_ sender: Any?) {
        trigger(action: "remove:", with: sender)
    }
    
    @objc func report(_ sender: Any?) {
        trigger(action: "report:", with: sender)
    }
    
    func trigger(action: String, with sender: Any?) {
        if let collectionView = self.superview as? UICollectionView {
            if let indexPath = collectionView.indexPath(for: self) {
                collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString(action), forItemAt: indexPath, withSender: sender)
            }
        }
    }
}
