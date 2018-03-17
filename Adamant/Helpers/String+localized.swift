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
			static let cancel = NSLocalizedString("Shared.Cancel", comment: "Shared alert 'Cancel' button. Used anywhere")
			static let ok = NSLocalizedString("Shared.Ok", comment: "Shared alert 'Ok' button. Used anywhere")
			static let save = NSLocalizedString("Shared.Save", comment: "Shared alert 'Save' button. Used anywhere")
			static let settings = NSLocalizedString("Shared.Settings", comment: "Shared alert 'Settings' button. Used to go to system Settings app, on application settings page. Should be same as Settings application title.")
			
			// MARK: Titles and messages
			static let error = NSLocalizedString("Shared.Error", comment: "Shared alert 'Error' title. Used anywhere")
			static let done = NSLocalizedString("Shared.Done", comment: "Shared alert Done message. Used anywhere")
			
			// MARK: Notifications
			static let copiedToPasteboardNotification = NSLocalizedString("Shared.CopiedToPasteboard", comment: "Shared alert notification: message about item copied to pasteboard.")
		}
		
		private init() { }
	}
	
}
