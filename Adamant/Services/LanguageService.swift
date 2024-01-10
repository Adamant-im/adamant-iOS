//
//  LanguageService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class LanguageStorageService: LanguageStorageProtocol {
    func getLanguage() -> Language {
        let raw = UserDefaults.standard.string(forKey: StoreKey.language.language) ?? ""
        let language: Language = .init(rawValue: raw) ?? .auto
        return language
    }
    
    func setLanguage(_ language: Language) {
        UserDefaults.standard.set(language.rawValue, forKey: StoreKey.language.language)
    }
}
