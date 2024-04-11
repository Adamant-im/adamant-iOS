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
        text.backgroundColor = .clear
        text.isEditable = false
        
        let attributedString = NSMutableAttributedString(
            attributedString: MarkdownParser().parse(self.text)
        )
        
        attributedString.apply(font: UIFont.adamantPrimary(ofSize: 18), alignment: .center)
        text.attributedText = attributedString
        text.linkTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.adamant.active]

        return text
    }()
    
    private let image: UIImage?
    private let text: String
    
    init(image: UIImage?, text: String) {
        self.image = image
        self.text = text
        super.init(frame: .zero)
        
        setupView()
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
}
