//
//  AdamantLocalized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public extension String {
    enum adamant {}
    
    static func localized(_ key: String, comment: String = .empty) -> String {
        guard let languageRaw = UserDefaults.standard.string(forKey: StoreKey.language.language),
              !languageRaw.isEmpty,
              languageRaw != Language.auto.rawValue,
              let path = Bundle.module.path(forResource: languageRaw, ofType: "lproj")
        else {
            return NSLocalizedString(key, bundle: .module, comment: comment)
        }
        
        let bundle: Bundle = Bundle(path: path) ?? .module
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}
