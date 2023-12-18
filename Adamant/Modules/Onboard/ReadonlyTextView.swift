//
//  ReadonlyTextView.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

final class ReadonlyTextView: UITextView {
    override var selectedTextRange: UITextRange? {
        get {
            return nil
        }
        set {}
    }
}
