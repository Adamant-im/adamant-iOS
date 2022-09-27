//
//  WarningView.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class WarningView: UIView {
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var availableEmojis = [
        "😔",
        "😟",
        "😭",
        "😰",
        "😨",
        "🤭",
        "😯",
        "😣",
        "😖",
        "🤕"
    ]
    
    func setRandomEmoji() {
        if let face = availableEmojis.randomElement() {
            emojiLabel.text = face
        } else {
            emojiLabel.text = "😭"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setRandomEmoji()
    }
}
