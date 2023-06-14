//
//  ContributeFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SwiftUI

@MainActor
struct ContributeFactory {
    let crashliticsService: CrashlyticsService
    
    func makeViewController() -> UIViewController {
        UIHostingController(
            rootView: TestView(
                viewModel: .init(crashliticsService: crashliticsService)
            )
        )
    }
}
