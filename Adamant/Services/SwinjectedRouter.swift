//
//  SwinjectedRouter.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject

class SwinjectedRouter: Router {
	weak var container: Container?
	
	func get(scene: AdamantScene) -> UIViewController {
		return scene.factory(container!)
	}
}
