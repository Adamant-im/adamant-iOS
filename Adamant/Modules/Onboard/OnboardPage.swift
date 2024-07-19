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
import SafariServices

final class OnboardPage: SwiftyOnboardPage {
    
    private lazy var mainImageView = UIImageView(image: image)
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.textColor = UIColor.adamant.active
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.delegate = self
        
        let attributedString = NSMutableAttributedString(
            attributedString: MarkdownParser().parse(self.text)
        )
        
        attributedString.apply(font: UIFont.adamantPrimary(ofSize: 18), alignment: .center)
        textView.attributedText = attributedString
        textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.adamant.active]
        
        return textView
    }()
    
    private let image: UIImage?
    private let text: String
    
    var tapURLCompletion: ((URL) -> Void)?
    
    init(image: UIImage?, text: String) {
        self.image = image
        self.text = text
        super.init(frame: .zero)
        
        setupView()
        layoutScreen()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(mainImageView)
        addSubview(textView)
        
        let space = UIScreen.main.bounds.height / 1.7
        mainImageView.contentMode = .scaleAspectFit
        mainImageView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.top.equalTo(safeAreaLayoutGuide).offset(50)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-space)
        }
    
        textView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-150)
            make.height.equalTo(260)
        }
    }
    
    private func layoutScreen() {
        if UIScreen.main.bounds.height == 667 {
            textView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(-120)
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension OnboardPage: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        tapURLCompletion?(URL)
        return false
    }
}
