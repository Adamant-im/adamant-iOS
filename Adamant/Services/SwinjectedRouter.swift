//
//  SwinjectedRouter.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SwinjectStoryboard

class SwinjectedRouter: Router {
	private var storyboards = [AdamantStory: UIStoryboard]()
	
	func get(story: AdamantStory) -> UIStoryboard {
		if let storyboard = storyboards[story] {
			return storyboard
		} else {
			let storyboard = SwinjectStoryboard.create(name: story.name, bundle: nil)
			storyboards[story] = storyboard
			return storyboard
		}
	}
	
	func get(scene: AdamantScene) -> UIViewController {
		return get(story: scene.story).instantiateViewController(withIdentifier: scene.identifier)
	}
}
