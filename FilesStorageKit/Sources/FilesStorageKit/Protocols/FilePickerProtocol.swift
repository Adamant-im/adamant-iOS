//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 11.02.2024.
//

import Foundation
import UIKit

protocol FilePickerProtocol {
    func startPicker(
        window: UIWindow,
        completion: (([FileResult]) -> Void)?
    )
}
