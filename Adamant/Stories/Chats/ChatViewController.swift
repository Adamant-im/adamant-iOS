//
//  ChatViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 15.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {

	// MARK: - Properties
	var chatroom: Chatroom?
	
	
	// MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let chatroom = chatroom {
			self.navigationItem.title = chatroom.id
		}
    }
}
