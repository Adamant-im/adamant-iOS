//
//  VibroService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

// MARK: - Notifications
extension Notification.Name {
    struct AdamantVibroService {
        static let presentVibrationRow = Notification.Name("adamant.vibroService.presentVibrationRow")
        
    }
}

@MainActor
protocol VibroService: AnyObject {
    func applyVibration(_ type: AdamantVibroType)
}
