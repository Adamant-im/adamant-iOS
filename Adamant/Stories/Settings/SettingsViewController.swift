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
		static let title = NSLocalizedString("Config.title", comment: "Config: scene title")
		
		static let stayInTurnOff = NSLocalizedString("Do not stay logged in", comment: "Config: turn off 'Stay Logged In' confirmation")
		static let biometryOnReason = NSLocalizedString("Use biometry to log in", comment: "Config: Authorization reason for turning biometry on")
		static let biometryOffReason = NSLocalizedString("Do not use biometry to log in", comment: "Config: Authorization reason for turning biometry off")
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
				return NSLocalizedString("Settings", comment: "Config: Settings section")
				
			case .applicationInfo:
				return NSLocalizedString("Application info", comment: "Config: Application Info section")
				
			case .utilities:
				return NSLocalizedString("Utilities", comment: "Config: Utilities section")
			}
		}
	}
	
	enum Rows {
		case version
		case qrPassphraseGenerator
		case stayLoggedIn
		case biometry
		case notifications
		
		var localized: String {
			switch self {
			case .version:
				return NSLocalizedString("Version", comment: "Config: Version row")
				
			case .qrPassphraseGenerator:
				return NSLocalizedString("Generate QR with passphrase", comment: "Config: Generate QR with passphrase row")
				
			case .stayLoggedIn:
				return NSLocalizedString("Stay Logged in", comment: "Config: Stay logged option")
				
			case .biometry:
				return ""
				
			case .notifications:
				return NSLocalizedString("Notifications", comment: "Config: Show notifications")
			}
		}
		
		var tag: String {
			switch self {
			case .biometry: return "bio"
			case .stayLoggedIn: return "in"
			case .version: return "ver"
			case .qrPassphraseGenerator: return "qr"
			case .notifications: return "ntfy"
			}
		}
	}
	
	
	// MARK: Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var localAuth: LocalAuthentication!
	var notificationsService: NotificationsService!
	var router: Router!
	
	
	// MARK: Properties
	var showBiometryRow = false
	var pinpadRequest: SettingsViewController.PinpadRequest?
	
	
	// MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
		self.navigationItem.title = String.adamantLocalized.settings.title
		navigationOptions = .Disabled
		showBiometryRow = accountService.hasStayInAccount
		
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
				guard let showBiometry = self?.showBiometryRow else {
					return true
				}
				
				return !showBiometry
			})
			
			switch localAuth.biometryType {
			case .touchID: $0.title = "Touch ID"
			case .faceID: $0.title = "Face ID"
			case .none: break
			}
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
		<<< SwitchRow() {
			$0.tag = Rows.notifications.tag
			$0.title = Rows.notifications.localized
			$0.value = notificationsService.notificationsEnabled
			
			$0.hidden = Condition.function([Rows.stayLoggedIn.tag], { form -> Bool in
				guard let row: SwitchRow = form.rowBy(tag: Rows.stayLoggedIn.tag), let value = row.value else {
					return true
				}
				
				return !value
			})
		}.onChange({ [weak self] row in
			guard let enabled = row.value else { return }
			self?.setNotifications(enabled: enabled)
		}).cellUpdate({ (cell, _) in
			if let label = cell.textLabel {
				label.font = UIFont.adamantPrimary(size: 17)
				label.textColor = UIColor.adamantPrimary
			}
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
		NotificationCenter.default.addObserver(forName: .adamantUserLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.tableView.reloadData()
			
			guard let form = self?.form, let accountService = self?.accountService else {
				return
			}
			
			self?.showBiometryRow = accountService.hasStayInAccount
			
			if let row: SwitchRow = form.rowBy(tag: Rows.stayLoggedIn.tag) {
				row.value = accountService.hasStayInAccount
			}
			
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				row.value = accountService.hasStayInAccount && accountService.useBiometry
				row.evaluateHidden()
			}
		}
		
		// MARK: Notifications
		NotificationCenter.default.addObserver(forName: .adamantShowNotificationsChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
			guard let row: SwitchRow = self?.form.rowBy(tag: Rows.notifications.tag), let value = self?.notificationsService.notificationsEnabled else {
				return
			}
			
			row.value = value
			row.updateCell()
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


// MARK: - Properties
extension SettingsViewController {
	func setNotifications(enabled: Bool) {
		guard enabled != notificationsService.notificationsEnabled else {
			return
		}
		
		notificationsService.setNotificationsEnabled(enabled) { [weak self] result in
			switch result {
			case .success:
				break
				
			case .denied(error: _):
				DispatchQueue.main.async {
					let alert = UIAlertController(title: nil, message: String.adamantLocalized.notifications.notificationsDisabled, preferredStyle: .alert)
					
					alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default) { _ in
						DispatchQueue.main.async {
							if let row: SwitchRow = self?.form.rowBy(tag: Rows.notifications.tag) {
								row.value = false
								row.updateCell()
							}
							
							if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
								UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
							}
						}
					})
					
					alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: { _ in
						if let row: SwitchRow = self?.form.rowBy(tag: Rows.notifications.tag) {
							row.value = false
							row.updateCell()
						}
					}))
					
					self?.present(alert, animated: true, completion: nil)
				}
			}
		}
	}
}



