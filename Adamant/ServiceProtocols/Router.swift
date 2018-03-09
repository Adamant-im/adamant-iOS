//
//  Router.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

// MARK: - Adamant Story struct
struct AdamantStory: Equatable, Hashable {
	let name: String
	
	init(_ name: String) {
		self.name = name
	}
	
	static func ==(lhs: AdamantStory, rhs: AdamantStory) -> Bool {
		return lhs.name == rhs.name
	}
	
	var hashValue: Int {
		return name.hashValue &* 171717
	}
}

// MARK: - Adamant Scene
struct AdamantScene: Equatable, Hashable {
	let identifier: String
	let story: AdamantStory
	
	init(story: AdamantStory, identifier: String) {
		self.story = story
		self.identifier = identifier
	}
	
	static func ==(lhs: AdamantScene, rhs: AdamantScene) -> Bool {
		return lhs.identifier == rhs.identifier
	}
	
	var hashValue: Int {
		return identifier.hashValue ^ story.hashValue &* 717171
	}
}


// MARK: - Adamant Router
protocol Router: class {
	func get(story: AdamantStory) -> UIStoryboard
	func get(scene: AdamantScene) -> UIViewController
}
