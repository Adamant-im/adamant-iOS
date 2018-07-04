//
//  SecurityViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Eureka
import SafariServices
import Haring

class SecurityViewController: FormViewController {
	
	enum PinpadRequest {
		case createPin
		case reenterPin(pin: String)
		case turnOffPin
		case turnOnBiometry
		case turnOffBiometry
	}
	
	// MARK: - Section & Rows
	
	enum Sections {
		case stayIn
		case notifications
		case ansDescription
		
		var tag: String {
			switch self {
			case .stayIn: return "ss"
			case .notifications: return "st"
			case .ansDescription: return "ans"
			}
		}
		
		var localized: String {
			switch self {
			case .stayIn: return "Stay in"
			case .notifications: return "Notifications type"
			case .ansDescription: return "About ANS"
			}
		}
	}
	
	enum Rows {
		case stayIn, biometry
		case notificationsMode
		case description, github
		
		var tag: String {
			switch self {
			case .stayIn: return "rs"
			case .biometry: return "rb"
			case .notificationsMode: return "rn"
			case .description: return "rd"
			case .github: return "git"
			}
		}
		
		var localized: String {
			switch self {
			case .stayIn: return "Stay logged in"
			case .biometry: return "Biometry"
			case .notificationsMode: return "Notifications"
			case .description: return "Description"
			case .github: return "Visit GitHub"
			}
		}
	}
	
	
	// MARK: - Dependencies
	
	var accountService: AccountService!
	var dialogService: DialogService!
	var notificationsService: NotificationsService!
	var localAuth: LocalAuthentication!
	var router: Router!
	
	
	// MARK: - Properties
	var showLoggedInOptions = false
	var pinpadRequest: SettingsViewController.PinpadRequest?
	
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.title = String.adamantLocalized.settings.title
		navigationOptions = .Disabled
		showLoggedInOptions = accountService.hasStayInAccount
		
		
		// MARK: StayIn
		// Stay logged in
		let stayInRow = SwitchRow() {
			$0.tag = Rows.stayIn.tag
			$0.title = Rows.stayIn.localized
			$0.value = accountService.hasStayInAccount
		}.onChange { [weak self] row in
			guard let enabled = row.value else {
				return
			}
			
			self?.setStayLoggedIn(enabled: enabled)
		}
		
		// Biometry
		let biometryRow = SwitchRow() {
			$0.tag = Rows.biometry.tag
			$0.title = localAuth.biometryType.localized
			$0.value = accountService.useBiometry
			
			$0.hidden = Condition.function([], { [weak self] _ -> Bool in
				guard let showBiometry = self?.showLoggedInOptions else {
					return true
				}
				
				return !showBiometry
			})
		}.onChange { [weak self] row in
			let value = row.value ?? false
			self?.setBiometry(enabled: value)
		}
		
		let stayInSection = Section(Sections.stayIn.localized) {
			$0.tag = Sections.stayIn.tag
		}
		
		stayInSection.append(contentsOf: [stayInRow, biometryRow])
		form.append(stayInSection)
		
		
		// MARK: Notifications
		// Type
		let nType = ActionSheetRow<NotificationsMode>() {
			$0.tag = Rows.notificationsMode.tag
			$0.title = Rows.notificationsMode.localized
			$0.selectorTitle = Rows.notificationsMode.localized
			$0.options = [.disabled, .backgroundFetch, .push]
			$0.value = notificationsService.notificationsMode
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}.onChange { [weak self] row in
			let mode = row.value ?? NotificationsMode.disabled
			self?.setNotificationMode(mode)
		}
		
		// Section
		let notificationsSection = Section(Sections.notifications.localized) {
			$0.tag = Sections.notifications.tag
			
			$0.hidden = Condition.function([], { [weak self] _ -> Bool in
				guard let showNotifications = self?.showLoggedInOptions else {
					return true
				}
				
				return !showNotifications
			})
		}
		
		notificationsSection.append(nType)
		form.append(notificationsSection)
		
		
		// MARK: ANS Description
		// Description
		let descriptionRow = TextAreaRow() {
			$0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
			$0.tag = Rows.description.tag
		}.cellUpdate { (cell, _) in
			let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
			cell.textView.attributedText = parser.parse(Rows.description.localized)
			cell.textView.isSelectable = false
			cell.textView.isEditable = false
		}
		
		// Github readme
		let githubRow = LabelRow() {
			$0.tag = Rows.github.tag
			$0.title = Rows.github.localized
		}.cellSetup { (cell, _) in
			cell.selectionStyle = .gray
			cell.accessoryType = .disclosureIndicator
		}.onCellSelection { [weak self] (_, row) in
			guard let url = URL(string: AdamantResources.ansReadmeUrl) else {
				fatalError("Failed to build ANS URL")
			}
			
			let safari = SFSafariViewController(url: url)
			safari.preferredControlTintColor = UIColor.adamantPrimary
			self?.present(safari, animated: true, completion: nil)
		}
		
		let ansSection = Section(Sections.ansDescription.localized) { $0.tag = Sections.ansDescription.tag }
		ansSection.append(contentsOf: [descriptionRow, githubRow])
		form.append(ansSection)
		
		
		// MARK: Notifications
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.reloadForm()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.stayInChanged, object: nil, queue: OperationQueue.main) { [weak self] notification in
			
			self?.reloadForm()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantNotificationService.notificationsModeChanged, object: nil, queue: OperationQueue.main) { [weak self] notification in
			guard let newMode = notification.userInfo?[AdamantUserInfoKey.NotificationsService.newNotificationsMode] as? NotificationsMode else {
				return
			}
			
			guard let row: ActionSheetRow<NotificationsMode> = self?.form.rowBy(tag: Rows.notificationsMode.tag) else {
				return
			}
			
			row.value = newMode
			row.updateCell()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	private func reloadForm() {
		showLoggedInOptions = accountService.hasStayInAccount
		tableView.reloadData()
		
		if let row: SwitchRow = form.rowBy(tag: Rows.stayIn.tag) {
			row.value = accountService.hasStayInAccount
		}
		
		if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
			row.value = accountService.hasStayInAccount && accountService.useBiometry
			row.evaluateHidden()
		}
		
		if let section = form.sectionBy(tag: Sections.notifications.tag) {
			section.evaluateHidden()
		}
	}
}
