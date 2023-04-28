//
//  NSAttributedText+Adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension NSAttributedString {
    func resolveLinkColor(_ color: UIColor = UIColor.adamant.active) -> NSMutableAttributedString {
        let mutableText = NSMutableAttributedString(attributedString: self)
        
        mutableText.enumerateAttribute(
            .link,
            in: NSRange(location: 0, length: self.length),
            options: []
        ) { (value, range, _) in
            guard value != nil else { return }
            
            mutableText.removeAttribute(.link, range: range)
            mutableText.addAttribute(
                .foregroundColor,
                value: color,
                range: range
            )
        }
        
        return mutableText
    }
}
