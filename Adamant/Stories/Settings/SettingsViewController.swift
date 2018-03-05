//
//  SettingsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

extension String.adamantLocalized {
	struct settings {
		static let biometryReason = NSLocalizedString("Authorize yourself", comment: "Config: Authorization reason for turning on/off biometry")
	}
}

class SettingsViewController: FormViewController {
	
	private let qrGeneratorSegue = "passphraseToQR"
	
	// MARK: Sections & Rows
	private enum Sections {
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
	
	private enum Rows {
		case version
		case qrPassphraseGenerator
		case stayLoggedIn
		case biometry
		
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
			}
		}
		
		var tag: String {
			switch self {
			case .biometry: return "bio"
			case .stayLoggedIn: return "in"
			case .version: return "ver"
			case .qrPassphraseGenerator: return "qr"
			}
		}
	}
	
	// MARK: Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var localAuth: LocalAuthentication!
	
	
	// MARK: Properties
	private var showBiometry = false
	
	
	// MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationOptions = .Disabled
		
		// MARK: Settings
		form +++ Section(Sections.settings.localized)
		
		// Stay logged in
		<<< SwitchRow() {
			$0.tag = Rows.stayLoggedIn.tag
			$0.title = Rows.stayLoggedIn.localized
			$0.value = false//accountService.stayLogged
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
			$0.value = false//accountService.biometryEnabled
			$0.hidden = Condition.function([], { [weak self] _ -> Bool in
				guard let showBiometry = self?.showBiometry else {
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
		
		// MARK: Utilities
		form +++ Section(Sections.utilities.localized)
		<<< LabelRow() {
			$0.title = Rows.qrPassphraseGenerator.localized
			$0.tag = Rows.qrPassphraseGenerator.tag
		}.cellSetup({ (cell, _) in
			cell.selectionStyle = .gray
		}).onCellSelection({ [weak self] (_, _) in
			guard let segue = self?.qrGeneratorSegue else {
				return
			}
			self?.performSegue(withIdentifier: segue, sender: nil)
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
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	private func setStayLoggedIn(enabled: Bool) {
		guard accountService.stayLogged != enabled else {
			return
		}
		
		accountService.stayLogged = enabled
		
		if enabled {
			switch localAuth.biometryType {
			case .touchID: showBiometry = true
			case .faceID: showBiometry = true
			case .none: showBiometry = false
			}
			
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				row.value = false
				row.evaluateHidden()
			}
		} else {
			accountService.biometryEnabled = false
			showBiometry = false
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				row.value = false
				row.evaluateHidden()
			}
		}
	}
	
	private func setBiometry(enabled: Bool) {
		guard accountService.stayLogged == true, accountService.biometryEnabled != enabled else {
			return
		}
		
		localAuth.authorizeUser(reason: String.adamantLocalized.settings.biometryReason) { [weak self] result in
			switch result {
			case .success:
				self?.accountService.biometryEnabled = enabled
				
			case .fallback:
				print("A user knopochku nazal")
				fallthrough
				
			case .failed:
				DispatchQueue.main.async {
					guard let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) else {
						return
					}
					
					if let value = self?.accountService.biometryEnabled {
						row.value = value
					} else {
						row.value = false
					}
					
					row.updateCell()
					row.evaluateHidden()
				}
			}
		}
	}
}
