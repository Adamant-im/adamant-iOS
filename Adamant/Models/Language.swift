//
//  Language.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

enum Language: String {
    case ru
    case en
    case de
    case zh
    case auto = ""
    
    var name: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        case .de: return "Deutschland"
        case .zh: return "中文"
        case .auto: return .localized("Language.Auto", comment: "Account tab: Language auto")
        }
    }
    
    static let all: [Language] = [.auto, .en, .ru, .de, .zh]
}
