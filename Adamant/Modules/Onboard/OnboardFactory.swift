//
//  OnboardFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 18/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Swinject
import UIKit

@MainActor
struct OnboardFactory {
    func makeOnboardVC() -> UIViewController {
        OnboardViewController(nibName: "OnboardViewController", bundle: nil)
    }

    func makeEulaVC() -> UIViewController {
        EulaViewController(nibName: "EulaViewController", bundle: nil)
    }
}
