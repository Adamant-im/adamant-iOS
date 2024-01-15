//
//  LanguageStorageProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

protocol LanguageStorageProtocol {
    func getLanguage() -> Language
    func setLanguage(_ language: Language)
}
