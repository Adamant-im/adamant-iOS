//
//  NotificationsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SafariServices
import Eureka
import Haring

extension String.adamantLocalized {
	struct notificationsScene {
		static let title = NSLocalizedString("Notifications.Title", comment: "Notifications: scene title")
		static let modesDescription = NSLocalizedString("Notifications.ModesDescription", comment: "Notifications: Modes description. Markdown supported.")
	}
}

enum NotificationMode: CustomStringConvertible {
	case disabled
	case backgroundFetch
	case push
	
	var localized: String {
		switch self {
		case .disabled:
			return NSLocalizedString("Notifications.Mode.NotificationsDisabled", comment: "Notifications: Disable notifications")
			
		case .backgroundFetch:
			return NSLocalizedString("Notifications.Mode.BackgroundFetch", comment: "Notifications: Use Background fetch notifications")
			
		case .push:
			return NSLocalizedString("Notifications.Mode.ApplePush", comment: "Notifications: Use Apple Push notifications")
		}
	}
	
	var description: String {
		return localized
	}
}

class NotificationsViewController: FormViewController {
	private static let githubUrl = URL.init(string: "https://github.com/Adamant-im/AdamantNotificationService/blob/master/README.md")
	
	// MARK: Sections & Rows
	enum Sections {
		case settings
		case types
		case ans
		
		var localized: String {
			switch self {
			case .settings:
				return NSLocalizedString("Notifications.Section.Settings", comment: "Notifications: Notifications settings")
				
			case .types:
				return NSLocalizedString("Notifications.Section.NotificationsType", comment: "Notifications: Selected notifications types")
				
			case .ans:
				return NSLocalizedString("Notifications.Section.AboutANS", comment: "Notifications: About ANS")
			}
		}
		
		var tag: String {
			switch self {
			case .settings: return "sttngs"
			case .types: return "tps"
			case .ans: return "ans"
			}
		}
	}
	
	enum Rows {
		case notificationsMode
		case messages
		case transfers
		case description
		case github
		
		var localized: String {
			switch self {
			case .notificationsMode:
				return NSLocalizedString("Notifications.Row.Mode", comment: "Notifications: Mode")
				
			case .messages:
				return NSLocalizedString("Notifications.Row.Messages", comment: "Notifications: Send new messages notifications")
			
			case .transfers:
				return NSLocalizedString("Notifications.Row.Transfers", comment: "Notifications: Send new transfers notifications")
				
			case .description:
				return String.adamantLocalized.notificationsScene.modesDescription
				
			case .github:
				return NSLocalizedString("Notifications.Row.VisitGithub", comment: "Notifications: Visit Github")
			}
		}
		
		var tag: String {
			switch self {
			case .notificationsMode: return "md"
			case .messages: return "msgs"
			case .transfers: return "trsfsrs"
			case .description: return "dscrptn"
			case .github: return "gthb"
			}
		}
	}
	
	// MARK: Properties
	
	private(set) var notificationMode: NotificationMode = .disabled
	
	private var notificationTypesHidden: Bool = true
	
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.title = String.adamantLocalized.notificationsScene.title
		navigationOptions = .Disabled
		
		// MARK: Modes
		form +++ Section(Sections.settings.localized) {
			$0.tag = Sections.settings.tag
		}
		
		<<< ActionSheetRow<NotificationMode>() {
			$0.tag = Rows.notificationsMode.tag
			$0.title = Rows.notificationsMode.localized
			$0.selectorTitle = Rows.notificationsMode.localized
			$0.options = [.disabled, .backgroundFetch, .push]
			$0.value = NotificationMode.disabled
		}.onChange({ [weak self] row in
			guard let mode = row.value else {
				return
			}
			
			self?.setNotificationMode(mode)
		}).cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
		
		// MARK: Types
		+++ Section(Sections.types.localized) {
			$0.tag = Sections.types.tag
			$0.hidden = Condition.function([Rows.notificationsMode.tag], { [weak self] _ -> Bool in
				guard let notificationTypesHidden = self?.notificationTypesHidden else {
					return true
				}
				return notificationTypesHidden
			})
		}
		
		<<< SwitchRow() {
			$0.tag = Rows.messages.tag
			$0.title = Rows.messages.localized
		}
		
		<<< SwitchRow() {
			$0.tag = Rows.transfers.tag
			$0.title = Rows.transfers.localized
		}
		
		
		// MARK: ANS
		
		+++ Section(Sections.ans.localized) {
			$0.tag = Sections.ans.tag
		}
		
		<<< TextAreaRow() {
			$0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
			$0.tag = Rows.description.tag
		}.cellUpdate({ (cell, _) in
			let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
			cell.textView.attributedText = parser.parse(Rows.description.localized)
			cell.textView.isSelectable = false
			cell.textView.isEditable = false
		})
			
		<<< LabelRow() {
			$0.title = Rows.github.localized
			$0.tag = Rows.github.tag
		}.cellSetup({ (cell, _) in
			cell.selectionStyle = .gray
		}).onCellSelection({ [weak self] (_, row) in
			guard let url = NotificationsViewController.githubUrl else {
				return
			}
			
			let safari = SFSafariViewController(url: url)
			safari.preferredControlTintColor = UIColor.adamantPrimary
			self?.present(safari, animated: true, completion: nil)
		}).cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
	}
	
	// MARK: Logic
	
	func setNotificationMode(_ mode: NotificationMode) {
		guard mode != notificationMode else {
			return
		}
		
		print(mode.localized)
		
		notificationMode = mode;
		notificationTypesHidden = mode == .disabled
		
//		switch mode {
//		case .disabled:
//			return
//
//		case .backgroundFetch:
//			return
//
//		case .push:
//			return
//		}
	}
}
