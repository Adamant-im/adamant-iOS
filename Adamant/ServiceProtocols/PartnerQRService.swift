//
//  PartnerQRService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol PartnerQRService: AnyObject, Sendable {
    func setIncludeNameEnabled(_ value: Bool)
    func isIncludeNameEnabled() -> Bool
    func setIncludeURLEnabled(_ value: Bool)
    func isIncludeURLEnabled() -> Bool
}
