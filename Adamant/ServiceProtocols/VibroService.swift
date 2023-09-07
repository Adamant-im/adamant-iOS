//
//  VibroService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol VibroService: AnyObject {
    func applyVibration(_ type: AdamantVibroType)
}
