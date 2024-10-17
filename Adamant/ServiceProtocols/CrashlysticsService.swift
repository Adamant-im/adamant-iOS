//
//  CrashlyticsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

@MainActor
protocol CrashlyticsService: AnyObject, Sendable {
    func configureIfNeeded()
    func setCrashlyticsEnabled(_ value: Bool)
    func isCrashlyticsEnabled() -> Bool
}
