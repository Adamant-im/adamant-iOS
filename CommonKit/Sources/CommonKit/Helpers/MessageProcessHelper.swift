//
//  MessageProcessHelper.swift
//
//
//  Created by Yana Silosieva on 29.04.2024.
//

import Foundation
import UIKit

public final class MessageProcessHelper {
    public static func process(_ text: String) -> String {
        text.replacingOccurrences(of: "\n", with: "↵ ")
    }
    
    public static func process(attributedText: NSMutableAttributedString) -> NSMutableAttributedString {
        attributedText.mutableString.replaceOccurrences(
            of: "\n",
            with: "↵ ",
            range: .init(location: .zero, length: attributedText.length)
        )
        let raw = attributedText.string
        
        var ranges: [Range<String.Index>] = []
        var searchRange = raw.startIndex..<raw.endIndex
        while let range = raw.range(of: "↵ ", options: [], range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<raw.endIndex
        }
        
        for range in ranges {
            attributedText.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: UIColor.lightGray,
                range: NSRange(range, in: raw)
            )
        }
        
        return attributedText
    }
}
