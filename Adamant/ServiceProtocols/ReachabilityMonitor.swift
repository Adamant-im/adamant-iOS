//
//  ReachabilityMonitor.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension Notification.Name {
	static let adamantReachabilityChanged = Notification.Name("adamantReachabilityChanged")
}

extension AdamantUserInfoKey {
	struct ReachabilityMonitor {
		/// Contains Connection object
		static let connection = "adamant.reachability.connection"
		
		private init() {}
	}
}

enum AdamantConnection {
	case none, wifi, cellular
}

protocol ReachabilityMonitor {
	var connection: AdamantConnection { get }
	
	func start()
	func stop()
}
