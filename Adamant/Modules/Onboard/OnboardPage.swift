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
import SnapKit

final class OnboardPage: SwiftyOnboardPage {
    
    private lazy var mainImageView = UIImageView(image: image)
    
    lazy var textView: UITextView = {
        let text = UITextView()
        text.textColor = UIColor.adamant.active
        text.text = self.text
        text.font = UIFont.adamantPrimary(ofSize: 24)
        text.backgroundColor = .clear
        text.isEditable = false
        return text
    }()
    
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
    
    private let image: UIImage?
    private let text: String
    
    init(image: UIImage?, text: String) {
        self.image = image
        self.text = text
        self.rawRichText = text
        super.init(frame: .zero)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        didLayoutSubviews = true
        adjustTextView()
    }
    
    private func setupView() {
        addSubview(mainImageView)
        addSubview(textView)
        
        mainImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(safeAreaLayoutGuide).offset(70)
        }
    
        textView.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalToSuperview().offset(-15)
        }
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
        textView.font = defaultFont
        textView.text = pureText
        adjustTextViewFontSize()
        
        let fontSize = textView.font!.pointSize
        
        guard maxFontSize != fontSize else {
            textView.text = nil
            textView.font = nil
            textView.attributedText = attributedString.resolveLinkColor()
            return
        }

        if let font = UIFont(name: fontName, size: fontSize) {
            attributedString.apply(font: font, alignment: .center)
            textView.text = nil
            textView.font = nil
            textView.attributedText = attributedString.resolveLinkColor()
        }
    }
    
    private func adjustTextViewFontSize() {
        guard !textView.text.isEmpty && !textView.bounds.size.equalTo(CGSize.zero) else {
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
