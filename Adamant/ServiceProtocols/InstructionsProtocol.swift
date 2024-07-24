//
//  InstructionsProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import UIKit

protocol InstructionsProtocol {
    func display(
        instructions: [Instruction],
        from viewController: UIViewController
    )
    
    func stop()
    func showNext()
}
