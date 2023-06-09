//
//  CrashlyticsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol CrashlyticsService: AnyObject {
    func setCrashlyticsEnabled(_ value: Bool)
    func isCrashlyticsEnabled() -> Bool
}
