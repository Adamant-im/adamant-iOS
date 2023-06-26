//
//  UIScrollView+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 10.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension UIScrollView {
    func scrollToBottom(animated: Bool) {
        let fullInsets = contentInset + safeAreaInsets
        let visibleHeight = bounds.height - fullInsets.top - fullInsets.bottom
        guard contentSize.height > visibleHeight else { return }
        
        let maxOffset = contentSize.height - bounds.height + contentInset.bottom + safeAreaInsets.bottom
        setContentOffset(.init(x: .zero, y: maxOffset), animated: animated)
    }
}
