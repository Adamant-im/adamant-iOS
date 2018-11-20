//
//  ChatCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit

protocol ChatCell: class {
//    var bubbleStyle: MessageStyle { get set }
    var bubbleBackgroundColor: UIColor? { get set }
}
