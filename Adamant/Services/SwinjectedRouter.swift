//
//  SwinjectedRouter.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject

final class SwinjectedRouter: Router {
    weak var container: Container?
    
    @MainActor func get(scene: AdamantScene) -> UIViewController {
        return scene.factory(container!)
    }
}
