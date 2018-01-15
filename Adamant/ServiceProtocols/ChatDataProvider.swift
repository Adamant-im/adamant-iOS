//
//  ChatDataProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

protocol ChatDataProvider {
	func reloadChats()
	func reset()
	
	func getChatroomsController() -> NSFetchedResultsController<Chatroom>?
	func getChatController(for: Chatroom) -> NSFetchedResultsController<ChatTransaction>?
}
