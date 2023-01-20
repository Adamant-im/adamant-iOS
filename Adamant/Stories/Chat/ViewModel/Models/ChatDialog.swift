//
//  ChatDialog.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

enum ChatDialog {
    case toast(String)
    case alert(String)
    case error(String)
    case richError(RichError)
    case freeTokenAlert
    case menu(sender: UIBarButtonItem)
}
