//
//  ChatMessagesCollection.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import Combine

final class ChatMessagesCollectionView: MessagesCollectionView {
    private var prevoiusFullInsets: UIEdgeInsets = .zero
    private var previousBottomOffset: CGFloat = .zero
    private var subscriptions = Set<AnyCancellable>()
    
    var animationEnabled = false
    
    var bottomOffset: CGFloat {
        contentHeightWithBottomInsets - bounds.maxY
    }
    
    init(didScroll: Observable<Void>) {
        super.init(frame: .zero, collectionViewLayout: MessagesCollectionViewFlowLayout())
        
        didScroll
            .sink { [weak self] in self?.moveContentIfInsetsChanged() }
            .store(in: &subscriptions)
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Saves the distance to the bottom while usual reloadData() saves the distance to the top
    func reloadDataWithFixedBottom() {
        let bottomOffset = self.bottomOffset
        reloadData()
        layoutIfNeeded()
        setBottomOffset(bottomOffset, animated: false)
    }

    /// Saves the distance to the bottom while usual reloadSections(_) saves the distance to the top
    func reloadSectionsWithFixedBottom(_ sections: IndexSet) {
        let bottomOffset = self.bottomOffset
        reloadSections(sections)
        layoutIfNeeded()
        setBottomOffset(bottomOffset, animated: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        moveContentIfInsetsChanged()
    }
}

private extension ChatMessagesCollectionView {
    var fullInsets: UIEdgeInsets {
        safeAreaInsets + contentInset
    }
    
    var maxVerticalOffset: CGFloat {
        contentHeightWithBottomInsets - bounds.height
    }
    
    var contentHeightWithBottomInsets: CGFloat {
        contentSize.height + fullInsets.bottom
    }
    
    func setBottomOffset(_ newValue: CGFloat, animated: Bool) {
        setVerticalContentOffsetSafely(
            contentHeightWithBottomInsets - bounds.height - newValue,
            animated: animated
        )
    }
    
    func setVerticalContentOffsetSafely(_ offset: CGFloat, animated: Bool) {
        guard maxVerticalOffset > .zero else { return }
        
        var offset = offset
        if offset < .zero {
            offset = .zero
        } else if offset > maxVerticalOffset {
            offset = maxVerticalOffset
        }
        
        setContentOffset(
            .init(x: contentOffset.x, y: offset),
            animated: animated && animationEnabled
        )
    }
    
    func moveContentIfInsetsChanged() {
        if prevoiusFullInsets != fullInsets {
            if !isDragging {
                setBottomOffset(previousBottomOffset, animated: true)
            }
            
            prevoiusFullInsets = fullInsets
        }
        
        previousBottomOffset = bottomOffset
    }
}
