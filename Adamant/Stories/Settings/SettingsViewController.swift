//
//  SettingsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class SettingsViewController: FormViewController {
	
	private let qrGeneratorSegue = "passphraseToQR"
	
	// MARK: Sections & Rows
	private enum Sections {
		case utilities
		case applicationInfo
		
		var localized: String {
			switch self {
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
		
		var localized: String {
			switch self {
			case .version:
				return NSLocalizedString("Version", comment: "Config: Version row")
				
			case .qrPassphraseGenerator:
				return NSLocalizedString("Generate QR with passphrase", comment: "Config: Generate QR with passphrase row")
			}
		}
		
		var tag: String {
			switch self {
			case .version: return "ver"
			case .qrPassphraseGenerator: return "qr"
			}
		}
	}
	
	// MARK: Dependencies
	var dialogService: DialogService!
	
	
	// MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationOptions = .Disabled
		
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
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
}
