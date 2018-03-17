//
//  Router.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject


// MARK: - Adamant Scene
struct AdamantScene {
	let identifier: String
	let factory: (Resolver) -> UIViewController
	
	init(identifier: String, factory: @escaping (Resolver) -> UIViewController) {
		self.identifier = identifier
		self.factory = factory
	}
}


// MARK: - Adamant Router
protocol Router: class {
	func get(scene: AdamantScene) -> UIViewController
}
