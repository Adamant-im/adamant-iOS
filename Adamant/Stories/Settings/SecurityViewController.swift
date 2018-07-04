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
	
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.title = String.adamantLocalized.settings.title
		navigationOptions = .Disabled
		
		// MARK: StayIn
		
		// Stay logged in
		let stayInRow = SwitchRow() {
			$0.tag = Rows.stayIn.tag
			$0.title = Rows.stayIn.localized
			$0.value = accountService.hasStayInAccount
		}
		
		// Biometry
		let biometryRow = SwitchRow() {
			$0.tag = Rows.biometry.tag
			$0.title = localAuth.biometryType.localized
			$0.value = accountService.useBiometry
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
		}
		
		let notificationsSection = Section(Sections.notifications.localized) {
			$0.tag = Sections.notifications.tag
		}
		
		notificationsSection.append(nType)
		form.append(notificationsSection)
		
		
		// MARK: ANS Description
		
		let descriptionRow = TextAreaRow() {
			$0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
			$0.tag = Rows.description.tag
		}.cellUpdate { (cell, _) in
			let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
			cell.textView.attributedText = parser.parse(Rows.description.localized)
			cell.textView.isSelectable = false
			cell.textView.isEditable = false
		}
		
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
	}
}
