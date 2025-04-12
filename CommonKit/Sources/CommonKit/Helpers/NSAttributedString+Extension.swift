//
//  NSAttributedString+Extension.swift
//  CommonKit
//
//  Created by Dmitrij Meidus on 03.04.25.
//

import Foundation
import UIKit

public extension NSAttributedString {
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

extension Array where Element == NSAttributedString {
    func joined() -> NSMutableAttributedString {
        self.reduce(into: NSMutableAttributedString()) { $0.append($1) }
    }
}
