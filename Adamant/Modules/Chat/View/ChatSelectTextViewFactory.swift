//
//  ChatSelectTextViewFactory.swift
//  Adamant
//
//  Created by Yana Silosieva on 13.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import Swinject
import UIKit
import SwiftUI

struct ChatSelectTextViewFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = parent
    }
    
    @MainActor
    func makeViewController(text: String) -> UIViewController {
        let view = SelectTextView(text: text)
        
        return UIHostingController(
            rootView: view
        )
    }
}
