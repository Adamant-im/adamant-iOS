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

extension NotificationsMode: CustomStringConvertible {
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
	
	// MARK: Dependencies
	
	var notificationsService: NotificationsService!
	
	
	// MARK: Properties
	
	private static let githubUrl = URL.init(string: "https://github.com/Adamant-im/AdamantNotificationService/blob/master/README.md")
	
	
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.title = String.adamantLocalized.notificationsScene.title
		navigationOptions = .Disabled
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantNotificationService.notificationsModeChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
			guard let mode = self?.notificationsService.notificationsMode else {
				return
			}
			
			if let row: ActionSheetRow<NotificationsMode> = self?.form.rowBy(tag: Rows.notificationsMode.tag) {
				row.value = mode
				row.updateCell()
			}
		}
		
		// MARK: Modes
		form +++ Section(Sections.settings.localized) {
			$0.tag = Sections.settings.tag
		}
		
		<<< ActionSheetRow<NotificationsMode>() {
			$0.tag = Rows.notificationsMode.tag
			$0.title = Rows.notificationsMode.localized
			$0.selectorTitle = Rows.notificationsMode.localized
			$0.options = [.disabled, .backgroundFetch, .push]
			$0.value = notificationsService.notificationsMode
		}.onChange({ [weak self] row in
			if let mode = row.value {
				self?.setNotificationMode(mode)
			}
		}).cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
			
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
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ [weak self] (_, row) in
			guard let url = NotificationsViewController.githubUrl else {
				return
			}
			
			let safari = SFSafariViewController(url: url)
			safari.preferredControlTintColor = UIColor.adamantPrimary
			self?.present(safari, animated: true, completion: nil)
		})
	}
	
	
	// MARK: Logic
	
	func setNotificationMode(_ mode: NotificationsMode) {
		guard mode != notificationsService.notificationsMode else {
			return
		}
		
		notificationsService.setNotificationsMode(mode) { [weak self] result in
			switch result {
			case .success:
				return
				
			case .denied(error: _):
				if let row: SwitchRow = self?.form.rowBy(tag: Rows.notificationsMode.tag) {
					row.value = false
					row.updateCell()
				}
				
				if let section = self?.form.sectionBy(tag: Sections.types.tag) {
					section.evaluateHidden()
				}
				
				DispatchQueue.main.async {
					self?.presentNotificationsDeniedError()
				}
			}
		}
	}
	
	private func presentNotificationsDeniedError() {
		let alert = UIAlertController(title: nil, message: String.adamantLocalized.notifications.notificationsDisabled, preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default) { _ in
			DispatchQueue.main.async {
				if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
					UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
				}
			}
		})
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
		
		present(alert, animated: true, completion: nil)
	}
}
