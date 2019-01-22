//
//  OnboardPage.swift
//  Adamant
//
//  Created by Anton Boyarkin on 04/10/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SwiftyOnboard

class OnboardPage: SwiftyOnboardPage {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var text: UITextView!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "OnboardPage", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        text.tintColor = UIColor.adamant.active
    }

}
