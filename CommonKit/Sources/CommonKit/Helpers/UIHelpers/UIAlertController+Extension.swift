//
//  UIAlertController+Extension.swift
//  
//
//  Created by Andrey Golubenko on 23.08.2023.
//

import UIKit

public extension UIAlertController {
    enum SourceView {
        case view(UIView)
        case barButtonItem(UIBarButtonItem)
    }
    
    convenience init(
        title: String?,
        message: String?,
        preferredStyleSafe: UIAlertController.Style,
        source: SourceView?
    ) {
        let style = source == nil && UIScreen.main.traitCollection.userInterfaceIdiom == .pad
            ? .alert
            : preferredStyleSafe
        
        self.init(title: title, message: message, preferredStyle: style)
        
        switch source {
        case let .view(view):
            popoverPresentationController?.sourceView = view
        case let .barButtonItem(item):
            popoverPresentationController?.barButtonItem = item
        case .none:
            break
        }
    }
}
