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
		static let stayInTurnOff = NSLocalizedString("Do not stay logged in", comment: "Config: turn off 'Stay Logged In' confirmation")
		static let biometryOnReason = NSLocalizedString("Use biometry to log in", comment: "Config: Authorization reason for turning biometry on")
		static let biometryOffReason = NSLocalizedString("Do not use biometry to log in", comment: "Config: Authorization reason for turning biometry off")
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
	
	// MARK: Pinpad
	private enum PinpadRequest {
		case createPin
		case reenterPin(pin: String)
		case turnOffPin
		case turnOnBiometry
		case turnOffBiometry
	}
	
	
	// MARK: Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var localAuth: LocalAuthentication!
	
	
	// MARK: Properties
	private var showBiometryRow = false
	private var pinpadRequest: PinpadRequest?
	
	
	// MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
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


// MARK: - Stay in
extension SettingsViewController {
	private func setStayLoggedIn(enabled: Bool) {
		guard accountService.hasStayInAccount != enabled else {
			return
		}
		
		if enabled { // Create pin and turn on Stay In
			pinpadRequest = .createPin
			let pinpad = PinpadViewController.adamantPinpad(biometryButton: .hidden)
			pinpad.commentLabel.text = String.adamantLocalized.pinpad.createPin
			pinpad.commentLabel.isHidden = false
			pinpad.delegate = self
			present(pinpad, animated: true, completion: nil)
		} else { // Validate pin and turn off Stay In
			pinpadRequest = PinpadRequest.turnOffPin
			let biometryButton: PinpadBiometryButtonType = accountService.useBiometry ? localAuth.biometryType.pinpadButtonType : .hidden
			let pinpad = PinpadViewController.adamantPinpad(biometryButton: biometryButton)
			pinpad.commentLabel.text = String.adamantLocalized.settings.stayInTurnOff
			pinpad.commentLabel.isHidden = false
			pinpad.delegate = self
			
			present(pinpad, animated: true, completion: nil)
		}
	}
	
	private func setBiometry(enabled: Bool) {
		guard showBiometryRow, accountService.hasStayInAccount, accountService.useBiometry != enabled else {
			return
		}
		
		let reason = enabled ? String.adamantLocalized.settings.biometryOnReason : String.adamantLocalized.settings.biometryOffReason
		localAuth.authorizeUser(reason: reason) { [weak self] result in
			switch result {
			case .success:
				self?.dialogService.showSuccess(withMessage: String.adamantLocalized.alert.done)
				self?.accountService.useBiometry = enabled
				
			case .cancel:
				DispatchQueue.main.async { [weak self] in
					if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
						row.value = self?.accountService.useBiometry
						row.updateCell()
					}
				}
				
			case .fallback:
				let pinpad = PinpadViewController.adamantPinpad(biometryButton: .hidden)
				
				if enabled {
					pinpad.commentLabel.text = String.adamantLocalized.settings.biometryOnReason
					self?.pinpadRequest = PinpadRequest.turnOnBiometry
				} else {
					pinpad.commentLabel.text = String.adamantLocalized.settings.biometryOffReason
					self?.pinpadRequest = PinpadRequest.turnOffBiometry
				}
				
				pinpad.commentLabel.isHidden = false
				pinpad.delegate = self
				
				DispatchQueue.main.async {
					self?.present(pinpad, animated: true, completion: nil)
				}

			case .failed:
				DispatchQueue.main.async {
					guard let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) else {
						return
					}

					if let value = self?.accountService.useBiometry {
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


// MARK: - PinpadViewControllerDelegate
extension SettingsViewController: PinpadViewControllerDelegate {
	func pinpad(_ pinpad: PinpadViewController, didEnterPin pin: String) {
		switch pinpadRequest {
			
		// MARK: User has entered new pin first time. Request re-enter pin
		case PinpadRequest.createPin?:
			pinpadRequest = PinpadRequest.reenterPin(pin: pin)
			pinpad.commentLabel.text = String.adamantLocalized.pinpad.reenterPin
			pinpad.clearPin()
			return
			
			
		// MARK: User has reentered pin. Save pin.
		case PinpadRequest.reenterPin(let pinToVerify)?:
			guard pin == pinToVerify else {
				pinpad.playWrongPinAnimation()
				pinpad.clearPin()
				break
			}
			
			accountService.setStayLoggedIn(pin: pin) { [weak self] result in
				switch result {
				case .success(account: _):
					self?.pinpadRequest = nil
					DispatchQueue.main.async {
						if let biometryType = self?.localAuth.biometryType,
							biometryType == .touchID || biometryType == .faceID,
							let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
							self?.showBiometryRow = true
							row.value = false
							row.updateCell()
							row.evaluateHidden()
						}
						
						pinpad.dismiss(animated: true, completion: nil)
					}
					
				case .failure(let error):
					self?.dialogService.showError(withMessage: error.localized)
				}
			}
			
			
		// MARK: Users want to turn off the pin. Validate and turn off.
		case PinpadRequest.turnOffPin?:
			guard accountService.validatePin(pin) else {
				pinpad.playWrongPinAnimation()
				pinpad.clearPin()
				break
			}
			
			accountService.dropSavedAccount()
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				showBiometryRow = false
				row.value = false
				row.updateCell()
				row.evaluateHidden()
			}
			
			pinpad.dismiss(animated: true, completion: nil)
			
			
		// MARK: User wants to turn on biometry
		case PinpadRequest.turnOnBiometry?:
			guard accountService.validatePin(pin) else {
				pinpad.playWrongPinAnimation()
				pinpad.clearPin()
				break
			}
			
			accountService.useBiometry = true
			pinpad.dismiss(animated: true, completion: nil)
			
			
		// MARK: User wants to turn off biometry
		case PinpadRequest.turnOffBiometry?:
			guard accountService.validatePin(pin) else {
				pinpad.playWrongPinAnimation()
				pinpad.clearPin()
				break
			}
			
			accountService.useBiometry = false
			pinpad.dismiss(animated: true, completion: nil)
			
		default:
			pinpad.dismiss(animated: true, completion: nil)
		}
	}
	
	func pinpadDidTapBiometryButton(_ pinpad: PinpadViewController) {
		switch pinpadRequest {
			
		// MARK: User wants to turn of StayIn with his face. Or finger.
		case PinpadRequest.turnOffPin?:
			localAuth.authorizeUser(reason: String.adamantLocalized.settings.stayInTurnOff, completion: { [weak self] result in
				switch result {
				case .success:
					self?.accountService.dropSavedAccount()
					
					DispatchQueue.main.async {
						if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
							self?.showBiometryRow = false
							row.value = false
							row.updateCell()
							row.evaluateHidden()
						}
						
						pinpad.dismiss(animated: true, completion: nil)
					}
					
				case .cancel: break
				case .fallback: break
				case .failed: break
				}
			})
			
		default:
			return
		}
	}
	
	func pinpadDidCancel(_ pinpad: PinpadViewController) {
		switch pinpadRequest {
			
		// MARK: User canceled turning on StayIn
		case PinpadRequest.createPin?:
			fallthrough
			
		case PinpadRequest.reenterPin(pin: _)?:
			if let row: SwitchRow = form.rowBy(tag: Rows.stayLoggedIn.tag) {
				row.value = false
				row.updateCell()
			}
			
		// MARK: User canceled turning off StayIn
		case PinpadRequest.turnOffPin?:
			if let row: SwitchRow = form.rowBy(tag: Rows.stayLoggedIn.tag) {
				row.value = true
				row.updateCell()
			}
			
		// MARK: User canceled Biometry On
		case PinpadRequest.turnOnBiometry?:
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				row.value = false
				row.updateCell()
			}
		
		// MARK: User canceled Biometry Off
		case PinpadRequest.turnOffBiometry?:
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				row.value = true
				row.updateCell()
			}
			
		default:
			break
		}
		
		pinpadRequest = nil
		pinpad.dismiss(animated: true, completion: nil)
	}
}
