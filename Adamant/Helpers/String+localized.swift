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
			static let productName = NSLocalizedString("adamant", comment: "Adamant: a product name")
			
			private init() {}
		}
		
		struct alert {
			static let cancel = NSLocalizedString("shared.button.cancel", comment: "Shared alert 'Cancel' button. Used anywhere")
			static let ok = NSLocalizedString("shared.button.ok", comment: "Shared alert 'Ok' button. Used anywhere")
			static let save = NSLocalizedString("shared.button.save", comment: "Shared alert 'Save' button. Used anywhere")
			static let copyToPasteboard = NSLocalizedString("shared.button.copy-to-pasteboard", comment: "Shared alert 'Copy to pasteboard' button. Used anywhere. Used for copy-paste info.")
			static let copiedToPasteboardNotification = NSLocalizedString("shared.notification.copied_to_pasteboard", comment: "Shared alert notification: message about item copied to pasteboard.")
			static let share = NSLocalizedString("shared.button.share", comment: "Shared alert 'Share' button. Used anywhere for presenting standart iOS 'Share' menu.")
		}
		
		private init() { }
	}
	
}
