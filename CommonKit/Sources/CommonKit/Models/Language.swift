//
//  Language.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

public extension Notification.Name {
    struct LanguageStorageService {
        public static let languageUpdated = Notification.Name("adamant.language.languageUpdated")
    }
}

public enum Language: String {
    case ru
    case en
    case de
    case zh
    case auto
    
    public var name: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        case .de: return "Deutsch"
        case .zh: return "中文"
        case .auto: return .localized("Language.Auto", comment: "Account tab: Language auto")
        }
    }
    
    public var locale: String {
        switch self {
        case .ru: return "ru_RU"
        case .en: return "en_EN"
        case .de: return "de_DE"
        case .zh: return "zh_CN"
        case .auto: return "en_EN"
        }
    }
    
    public static let all: [Language] = [.auto, .en, .ru, .de, .zh]
}
