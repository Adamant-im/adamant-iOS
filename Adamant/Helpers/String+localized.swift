//
//  String+localized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 14.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension String {
	public struct adamantLocalized {
		struct shared {
			static let productName = NSLocalizedString("ADAMANT", comment: "Product name")
			
			private init() {}
		}
		
		struct alert {
			// MARK: Buttons
			static let cancel = NSLocalizedString("Cancel", comment: "Shared alert 'Cancel' button. Used anywhere")
			static let ok = NSLocalizedString("Ok", comment: "Shared alert 'Ok' button. Used anywhere")
			static let save = NSLocalizedString("Save", comment: "Shared alert 'Save' button. Used anywhere")
			static let copyToPasteboard = NSLocalizedString("Copy to Pasteboard", comment: "Shared alert 'Copy' button. Used anywhere. Used for copy-paste info.")
			static let share = NSLocalizedString("Share", comment: "Shared alert 'Share' button. Used anywhere for presenting standart iOS 'Share' menu.")
			static let settings = NSLocalizedString("Settings", comment: "Shared alert 'Settings' button. Used to go to system Settings app, on application settings page. Should be same as Settings application title.")
			
			// MARK: Titles and messages
			static let error = NSLocalizedString("Error", comment: "Shared alert 'Error' title. Used anywhere")
			static let done = NSLocalizedString("Done", comment: "Shared alert Done message. Used anywhere")
			
			// MARK: Notifications
			static let copiedToPasteboardNotification = NSLocalizedString("Copied to Pasteboard", comment: "Shared alert notification: message about item copied to pasteboard.")
		}
		
		private init() { }
	}
	
}
