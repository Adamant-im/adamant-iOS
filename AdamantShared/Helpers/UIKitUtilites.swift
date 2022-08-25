//
//  UIKitUtilites.swift
//  Adamant
//
//  Created by Andrey on 25.08.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit

extension UICollectionView {
    func scrollToLastItem(animated: Bool) {
        let indexPath = IndexPath(
            row: numberOfItems(inSection: numberOfSections - 1) - 1,
            section: numberOfSections - 1
        )
        
        guard hasItemAtIndexPath(indexPath) else { return }
        scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    func hasItemAtIndexPath(_ indexPath: IndexPath) -> Bool {
        indexPath.section < numberOfSections
            && indexPath.row < numberOfItems(inSection: indexPath.section)
    }
}
