//
//  OnboardOverlay.swift
//  Adamant
//
//  Created by Anton Boyarkin on 04/10/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SwiftyOnboard

class OnboardOverlay: SwiftyOnboardOverlay {

    @IBOutlet weak var skip: UIButton!
    @IBOutlet weak var contentControl: PageControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "OnboardOverlay", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

}
