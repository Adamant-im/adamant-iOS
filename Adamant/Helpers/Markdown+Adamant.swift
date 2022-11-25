//
//  Markdown+Adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import MarkdownKit

// MARK: Detect simple ADM address
// - ex: U3716604363012166999
class MarkdownSimpleAdm: MarkdownElement {
    private static let regex = "U([0-9]{6,20})"

    open var regex: String {
        return MarkdownSimpleAdm.regex
    }

    open func regularExpression() throws -> NSRegularExpression {
      return try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
    }

    open func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
        let attributesColor = [
            NSAttributedString.Key.foregroundColor: UIColor.adamant.active,
            NSAttributedString.Key.underlineColor: UIColor.adamant.active
        ]
        
        let nsString = (attributedString.string as NSString)
        let address = nsString.substring(with: match.range)
        guard let url = URL(string: "adm:\(address)") else { return }
        attributedString.addAttribute(.link, value: url, range: match.range)
        attributedString.addAttributes(attributesColor, range: match.range)
    }
}

// MARK: Detect advanced ADM address
// - ex: [Джону Doe](adm:U9821606738809290000?label=John+Doe&message=Just+say+hello)
class MarkdownAdvancedAdm: MarkdownLink {
    private static let regex = "\\[[^\\(]*\\]\\(adm:[^\\s]+\\)"
    private static let onlyLinkRegex = "\\(adm:[^\\s]+\\)"
    private static let onlyAddressRegex = "U([0-9]{6,20})"
    
    override var regex: String {
        return MarkdownAdvancedAdm.regex
    }
    
    override func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
        let nsString = (attributedString.string as NSString)
        let urlString = nsString.substring(with: match.range)
        
        guard let onlyLinkRegex = try? NSRegularExpression(pattern: MarkdownAdvancedAdm.onlyLinkRegex, options: .dotMatchesLineSeparators),
              let onlyAddressRegex = try? NSRegularExpression(pattern: MarkdownAdvancedAdm.onlyAddressRegex, options: .dotMatchesLineSeparators)
        else {
            return
        }
        
        guard let linkMatch = onlyLinkRegex.firstMatch(in: urlString,
                                                       options: .withoutAnchoringBounds,
                                                       range: NSRange(
                                                        location: 0,
                                                        length: urlString.count
                                                       )),
              let addressMatch = onlyAddressRegex.firstMatch(in: urlString,
                                                             options: .withoutAnchoringBounds,
                                                             range: NSRange(
                                                                location: 0,
                                                                length: urlString.count
                                                             ))
        else {
            return
        }
        
        let urlLinkAbsoluteStart = match.range.location
        let linkURLString = nsString
            .substring(with: NSRange(location: urlLinkAbsoluteStart + linkMatch.range.location + 1, length: linkMatch.range.length - 2))
        let addressString = nsString
            .substring(with: NSRange(location: urlLinkAbsoluteStart + addressMatch.range.location, length: addressMatch.range.length))

        let nameString = nsString
            .substring(with: NSRange(location: match.range.location, length: 2))
        let separator = nameString != "[]" ? ":" : ""
        
        // deleting trailing markdown
        let trailingMarkdownRange = NSRange(location: urlLinkAbsoluteStart + linkMatch.range.location - 1, length: linkMatch.range.length + 1)
        attributedString.deleteCharacters(in: trailingMarkdownRange)
        
        // deleting leading markdown
        let leadingMarkdownRange = NSRange(location: match.range.location, length: 1)
        attributedString.deleteCharacters(in: leadingMarkdownRange)
        
        // insert address
        attributedString.insert(NSAttributedString(string: "\(separator)\(addressString)"), at: urlLinkAbsoluteStart + linkMatch.range.location - 2)
        
        let formatRange = NSRange(location: match.range.location,
                                  length: (linkMatch.range.location - 2) + addressString.count + separator.count)
        
        formatText(attributedString, range: formatRange, link: linkURLString)
        addAttributes(attributedString, range: formatRange, link: linkURLString)
    }
}
