//
//  SettingsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import MyLittlePinpad

extension String.adamantLocalized {
	struct settings {
		static let title = NSLocalizedString("SettingsPage.Title", comment: "Config: scene title")
		
		static let stayInTurnOff = NSLocalizedString("SettingsPage.DoNotStayLoggedIn", comment: "Config: turn off 'Stay Logged In' confirmation")
		static let biometryOnReason = NSLocalizedString("SettingsPage.UseBiometry", comment: "Config: Authorization reason for turning biometry on")
		static let biometryOffReason = NSLocalizedString("SettingsPage.DoNotUseBiometry", comment: "Config: Authorization reason for turning biometry off")
		
		private init() {}
	}
}

class SettingsViewController: FormViewController {
	// MARK: Sections & Rows
	enum Sections {
		case settings
		case utilities
		case applicationInfo
		
		var localized: String {
			switch self {
			case .settings:
				return NSLocalizedString("SettingsPage.Section.Settings", comment: "Config: Settings section")
				
			case .applicationInfo:
				return NSLocalizedString("SettingsPage.Section.ApplicationInfo", comment: "Config: Application Info section")
				
			case .utilities:
				return NSLocalizedString("SettingsPage.Section.Utilities", comment: "Config: Utilities section")
			}
		}
	}
	
	enum Rows {
		case version
		case qrPassphraseGenerator
		case stayLoggedIn
		case biometry
		case notifications
		case nodes
		
		var localized: String {
			switch self {
			case .version:
				return NSLocalizedString("SettingsPage.Row.Version", comment: "Config: Version row")
				
			case .qrPassphraseGenerator:
				return NSLocalizedString("SettingsPage.Row.GenerateQr", comment: "Config: Generate QR with passphrase row")
				
			case .stayLoggedIn:
				return NSLocalizedString("SettingsPage.Row.StayLoggedIn", comment: "Config: Stay logged option")
				
			case .biometry:
				return ""
				
			case .notifications:
				return NSLocalizedString("SettingsPage.Row.Notifications", comment: "Config: Show notifications")
				
			case .nodes:
				return String.adamantLocalized.nodesList.nodesListButton
			}
		}
		
		var tag: String {
			switch self {
			case .biometry: return "bio"
			case .stayLoggedIn: return "in"
			case .version: return "ver"
			case .qrPassphraseGenerator: return "qr"
			case .notifications: return "ntfy"
			case .nodes: return "nds"
			}
		}
	}
	
	
	// MARK: Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var localAuth: LocalAuthentication!
	var router: Router!
	
	
	// MARK: Properties
	var showLoggedInOptions = false
	var pinpadRequest: SettingsViewController.PinpadRequest?
	
	
	// MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
		self.navigationItem.title = String.adamantLocalized.settings.title
		navigationOptions = .Disabled
		showLoggedInOptions = accountService.hasStayInAccount
		
		// MARK: Settings
		form +++ Section(Sections.settings.localized)
		
		// Stay logged in
		<<< SwitchRow() {
			$0.tag = Rows.stayLoggedIn.tag
			$0.title = Rows.stayLoggedIn.localized
			$0.value = accountService.hasStayInAccount
		}.onChange({ [weak self] row in
			guard let enabled = row.value else { return }
			self?.setStayLoggedIn(enabled: enabled)
		}).cellUpdate({ (cell, _) in
			if let label = cell.textLabel {
				label.font = UIFont.adamantPrimary(size: 17)
				label.textColor = UIColor.adamantPrimary
			}
		})
		
		// Biometry
		<<< SwitchRow() {
			$0.tag = Rows.biometry.tag
			$0.value = accountService.useBiometry
			$0.hidden = Condition.function([], { [weak self] _ -> Bool in
				guard let showBiometry = self?.showLoggedInOptions else {
					return true
				}
				
				return !showBiometry
			})
			
			$0.title = localAuth.biometryType.localized
		}.onChange({ [weak self] row in
			guard let enabled = row.value else { return }
			self?.setBiometry(enabled: enabled)
		}).cellUpdate({ (cell, _) in
			if let label = cell.textLabel {
				label.font = UIFont.adamantPrimary(size: 17)
				label.textColor = UIColor.adamantPrimary
			}
		})
		
		// Notifications
		<<< LabelRow() {
			$0.title = Rows.notifications.localized
			$0.tag = Rows.notifications.tag
			$0.hidden = Condition.function([], { [weak self] _ -> Bool in
				guard let showNotifications = self?.showLoggedInOptions else {
					return true
				}
				
				return !showNotifications
			})
		}.cellSetup({ (cell, _) in
			cell.selectionStyle = .gray
		}).onCellSelection({ [weak self] (cell, _) in
			guard let nav = self?.navigationController, let vc = self?.router.get(scene: AdamantScene.Settings.notifications) else {
				return
			}
			nav.pushViewController(vc, animated: true)
		}).cellUpdate({ (cell, _) in
			if let label = cell.textLabel {
				label.font = UIFont.adamantPrimary(size: 17)
				label.textColor = UIColor.adamantPrimary
			}
			
			cell.accessoryType = .disclosureIndicator
		})
		
		// MARK: Utilities
		form +++ Section(Sections.utilities.localized)
		<<< LabelRow() {
			$0.title = Rows.qrPassphraseGenerator.localized
			$0.tag = Rows.qrPassphraseGenerator.tag
		}.cellSetup({ (cell, _) in
			cell.selectionStyle = .gray
		}).onCellSelection({ [weak self] (_, _) in
			guard let nav = self?.navigationController, let vc = self?.router.get(scene: AdamantScene.Settings.qRGenerator) else {
				return
			}
			nav.pushViewController(vc, animated: true)
		}).cellUpdate({ (cell, _) in
			if let label = cell.textLabel {
				label.font = UIFont.adamantPrimary(size: 17)
				label.textColor = UIColor.adamantPrimary
			}
			
			cell.accessoryType = .disclosureIndicator
		})
		
		
		// MARK: Application
		form +++ Section(Sections.applicationInfo.localized)
		<<< LabelRow() {
			$0.title = Rows.nodes.localized
			$0.tag = Rows.nodes.tag
			}.cellSetup({ (cell, _) in
				cell.selectionStyle = .gray
			}).onCellSelection({ [weak self] (_, _) in
				guard let nav = self?.navigationController, let vc = self?.router.get(scene: AdamantScene.Settings.nodesList) else {
					return
				}
				nav.pushViewController(vc, animated: true)
			}).cellUpdate({ (cell, _) in
				if let label = cell.textLabel {
					label.font = UIFont.adamantPrimary(size: 17)
					label.textColor = UIColor.adamantPrimary
				}
				
				cell.accessoryType = .disclosureIndicator
			})
		<<< LabelRow() {
			$0.title = Rows.version.localized
			$0.value = AdamantUtilities.applicationVersion
			$0.tag = Rows.version.tag
		}.cellSetup({ (cell, _) in
			cell.selectionStyle = .gray
		}).onCellSelection({ [weak self] (_, row) in
			let indexPath = row.indexPath
			let completion = {
				if let indexPath = indexPath {
					self?.tableView.deselectRow(at: indexPath, animated: true)
				}
			}
			
			self?.dialogService.presentShareAlertFor(string: AdamantUtilities.applicationVersion,
													 types: [.copyToPasteboard],
													 excludedActivityTypes: nil,
													 animated: true,
													 completion: completion)
		}).cellUpdate({ (cell, _) in
			if let label = cell.textLabel {
				label.font = UIFont.adamantPrimary(size: 17)
				label.textColor = UIColor.adamantPrimary
			}
			
			cell.accessoryType = .disclosureIndicator
		})
		
		
		// MARK: User login
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.tableView.reloadData()
			
			guard let form = self?.form, let accountService = self?.accountService else {
				return
			}
			
			self?.showLoggedInOptions = accountService.hasStayInAccount
			
			if let row: SwitchRow = form.rowBy(tag: Rows.stayLoggedIn.tag) {
				row.value = accountService.hasStayInAccount
			}
			
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				row.value = accountService.hasStayInAccount && accountService.useBiometry
				row.evaluateHidden()
			}
			
			if let row: LabelRow = form.rowBy(tag: Rows.notifications.tag) {
				row.evaluateHidden()
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}
