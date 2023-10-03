//
//  OnboardPage.swift
//  Adamant
//
//  Created by Anton Boyarkin on 04/10/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import MarkdownKit
import CommonKit

final class OnboardPage: SwiftyOnboardPage {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var bottomLabelConstraint: NSLayoutConstraint!
    
    private var didLayoutSubviews: Bool = false
    
    var rawRichText: String? {
        didSet {
            if didLayoutSubviews {
                adjustTextView()
            }
        }
    }
    
    var minFontSize: CGFloat = 12.0 {
        didSet {
            if didLayoutSubviews {
                adjustTextView()
            }
        }
    }
    
    var maxFontSize: CGFloat = 16.0 {
        didSet {
            if didLayoutSubviews {
                adjustTextView()
            }
        }
    }
    
    var fontName: String = "Exo2-Regular" {
        didSet {
            if didLayoutSubviews {
                adjustTextView()
            }
        }
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "OnboardPage", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        text.tintColor = UIColor.adamant.active
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        didLayoutSubviews = true
        adjustTextView()
    }
    
    private func adjustTextView() {
        guard
            let rawRichText = rawRichText,
            let defaultFont = UIFont(name: fontName, size: maxFontSize) else {
            return
        }
        
        let attributedString = NSMutableAttributedString(attributedString: MarkdownParser().parse(rawRichText))
        
        attributedString.apply(font: defaultFont, alignment: .center)
        
        let pureText = attributedString.string
        text.font = defaultFont
        text.text = pureText
        adjustTextViewFontSize()
        
        let fontSize = text.font!.pointSize
        
        guard maxFontSize != fontSize else {
            text.text = nil
            text.font = nil
            text.attributedText = attributedString
            return
        }

        if let font = UIFont(name: fontName, size: fontSize) {
            attributedString.apply(font: font, alignment: .center)
            text.text = nil
            text.font = nil
            text.attributedText = attributedString
        }
    }
    
    private func adjustTextViewFontSize() {
        guard let textView = text, !textView.text.isEmpty && !textView.bounds.size.equalTo(CGSize.zero) else {
            return
        }
        
        let textViewSize = textView.frame.size
        let fixedWidth = textViewSize.width
        let expectSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        
        var expectFont = textView.font
        if (expectSize.height > textViewSize.height) {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height > textViewSize.height) {
                // Check min
                if textView.font!.pointSize <= minFontSize {
                    textView.font = textView.font!.withSize(minFontSize)
                    return
                }
                
                // Shrink it more
                expectFont = textView.font!.withSize(textView.font!.pointSize - 1)
                textView.font = expectFont
            }
        } else {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height < textViewSize.height) {
                if textView.font!.pointSize >= maxFontSize {
                    textView.font = textView.font!.withSize(maxFontSize)
                    return
                }
                
                expectFont = textView.font
                textView.font = textView.font!.withSize(textView.font!.pointSize + 1)
            }
        }
    }
}
