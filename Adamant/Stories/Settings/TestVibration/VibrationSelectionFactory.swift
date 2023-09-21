//
//  VibrationSelectionFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SwiftUI

@MainActor
struct VibrationSelectionFactory {
    let vibroService: VibroService
    
    func makeViewController() -> UIViewController {
        UIHostingController(
            rootView: VibrationSelectionView(
                viewModel: .init(vibroService: vibroService)
            )
        )
    }
}
