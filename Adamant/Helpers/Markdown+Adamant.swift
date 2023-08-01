//
//  Markdown+Adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import MarkdownKit
import CommonKit

// MARK: Detect simple ADM address
// - ex: U3716604363012166999
final class MarkdownSimpleAdm: MarkdownElement {
    private static let regex = "U([0-9]{6,20})"
    
    var regex: String {
        return MarkdownSimpleAdm.regex
    }
    
    func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
    }
    
    func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
        let attributesColor: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.adamant.active,
            NSAttributedString.Key.underlineStyle: 0,
            NSAttributedString.Key.underlineColor: UIColor.clear
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
final class MarkdownAdvancedAdm: MarkdownLink {
    private static let regex = "\\[[^\\(]*\\]\\(adm:[^\\s]+\\)"
    private static let onlyLinkRegex = "\\(adm:[^\\s]+\\)"
    private static let onlyAddressRegex = "U([0-9]{6,20})"
    
    override var regex: String {
        return MarkdownAdvancedAdm.regex
    }
    
    var attributes: [NSAttributedString.Key: AnyObject] {
        var attributes = [NSAttributedString.Key: AnyObject]()
        if let font = font {
            attributes[NSAttributedString.Key.font] = font
        }
        if let color = color {
            attributes[NSAttributedString.Key.foregroundColor] = color
        }
        attributes[NSAttributedString.Key.underlineStyle] = 0 as AnyObject
        attributes[NSAttributedString.Key.underlineColor] = UIColor.clear
        return attributes
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
    
    override func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange, link: String) {
        attributedString.addAttributes(attributes, range: range)
    }
}

// MARK: Detect link ADM address
// - ex: https://anydomainOrIP?address=U9821606738809290000&label=John+Doe
final class MarkdownLinkAdm: MarkdownLink {
    private static let regex = "(?i)\\b((?:https?://|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+(\\?address=U([0-9]{6,20}))[^\\s()<>]+)+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"
    
    override var regex: String {
        return MarkdownLinkAdm.regex
    }
    
    var attributes: [NSAttributedString.Key: AnyObject] {
        var attributes = [NSAttributedString.Key: AnyObject]()
        if let font = font {
            attributes[NSAttributedString.Key.font] = font
        }
        if let color = color {
            attributes[NSAttributedString.Key.foregroundColor] = color
        }
        attributes[NSAttributedString.Key.underlineStyle] = 0 as AnyObject
        attributes[NSAttributedString.Key.underlineColor] = UIColor.clear
        return attributes
    }
    
    override func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
        let nsString = (attributedString.string as NSString)
        let urlString = nsString.substring(with: match.range)
        
        guard let adm = urlString.getAdamantAddress(),
              var urlComponents = URLComponents(string: "adm:\(adm.address)")
        else {
            return
        }
        
        var queryItems: [URLQueryItem] = []
        if let name = adm.name {
            queryItems.append(URLQueryItem(name: "label", value: name))
        }
        if let message = adm.message {
            queryItems.append(URLQueryItem(name: "message", value: message))
        }
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else { return }
        
        // replace url with adm address
        attributedString.replaceCharacters(in: match.range, with: adm.address)
        
        let formatRange = NSRange(location: match.range.location,
                                  length: adm.address.count)
        formatText(attributedString, range: formatRange, link: url.absoluteString)
        addAttributes(attributedString, range: formatRange, link: url.absoluteString)
    }
    
    override func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange, link: String) {
        attributedString.addAttributes(attributes, range: range)
    }
}

// MARK: Markdown Code
final class MarkdownCodeAdamant: MarkdownCommonElement {
    private static let regex = "\\`[^\\`]*(?:\\`\\`[^\\`]*)*\\`"
    private let char = "`"
    
    var font: MarkdownFont?
    var color: MarkdownColor?
    var textHighlightColor: MarkdownColor?
    var textBackgroundColor: MarkdownColor?
    
    var regex: String {
        return MarkdownCodeAdamant.regex
    }
    
    init(
        font: MarkdownFont? = MarkdownCode.defaultFont,
        color: MarkdownColor? = nil,
        textHighlightColor: MarkdownColor? = MarkdownCode.defaultHighlightColor,
        textBackgroundColor: MarkdownColor? = MarkdownCode.defaultBackgroundColor
    ) {
        self.font = font
        self.color = color
        self.textHighlightColor = textHighlightColor
        self.textBackgroundColor = textBackgroundColor
    }
    
    func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange) {
        var matchString: String = attributedString.attributedSubstring(from: range).string
        matchString = matchString.replacingOccurrences(of: char, with: "")
        attributedString.replaceCharacters(in: range, with: matchString)
        
        var codeAttributes = attributes
        
        textHighlightColor.flatMap {
            codeAttributes[NSAttributedString.Key.foregroundColor] = $0
        }
        textBackgroundColor.flatMap {
            codeAttributes[NSAttributedString.Key.backgroundColor] = $0
        }
        font.flatMap { codeAttributes[NSAttributedString.Key.font] = $0 }
        
        let updatedRange = (attributedString.string as NSString).range(of: matchString)
        attributedString.addAttributes(codeAttributes, range: NSRange(location: range.location, length: updatedRange.length))
    }
    
    func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
        addAttributes(attributedString, range: match.range)
    }
}
