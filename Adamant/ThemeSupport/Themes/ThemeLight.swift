//
//  ThemeLight.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit

class ThemeLight: ThemeBase {
    override var title: String {
        return NSLocalizedString("AccountTab.Row.Theme.Light", comment: "Account tab: 'Theme' row value 'Light'")
    }
    
    init() throws {
        try super.init(fileName: "ThemeLight")
    }
}
