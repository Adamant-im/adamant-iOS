//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 11.02.2024.
//

import Foundation
import UIKit
import CommonKit

protocol FilePickerProtocol {
    func startPicker(completion: (([FileResult]) -> Void)?)
}
