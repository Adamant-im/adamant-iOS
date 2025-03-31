//
//  ChatSelectTextViewFactory.swift
//  Adamant
//
//  Created by Yana Silosieva on 13.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import SwiftUI
import Swinject
import UIKit

struct ChatSelectTextViewFactory {
    @MainActor
    func makeViewController(text: String) -> UIViewController {
        let view = SelectTextView(text: text)

        return UIHostingController(
            rootView: view
        )
    }
}
