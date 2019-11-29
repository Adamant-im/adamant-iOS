//
//  OnboardRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 18/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene {
    struct Onboard {
        static let welcome = AdamantScene(identifier: "OnboardViewController") { r in
            let c = OnboardViewController(nibName: "OnboardViewController", bundle: nil)
            return c
        }
        
        static let eula = AdamantScene(identifier: "EulaViewController") { r in
            let c = EulaViewController(nibName: "EulaViewController", bundle: nil)
            return c
        }
    }
}
