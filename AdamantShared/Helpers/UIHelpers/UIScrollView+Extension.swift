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
        guard contentSize.height >= bounds.size.height else { return }
        
        scrollRectToVisible(
            .init(
                x: contentSize.width - bounds.width,
                y: contentSize.height - bounds.height,
                width: bounds.width,
                height: bounds.height
            ),
            animated: animated
        )
    }
}
