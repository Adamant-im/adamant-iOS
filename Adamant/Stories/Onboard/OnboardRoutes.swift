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
        static let welcome = AdamantScene(identifier: "WelcomeViewController") { r in
            let c = WelcomeViewController(nibName: "WelcomeViewController", bundle: nil)
            return c
        }
    }
}
