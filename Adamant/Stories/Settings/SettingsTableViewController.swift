//
//  SettingsTableViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
	
	private let qrGeneratorSegue = "passphraseToQR"
	
	// MARK: Sections & Rows
	private enum Section: Int {
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
	
	private enum Row {
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
	}
	
	// MARK: Dependencies
	var dialogService: DialogService!
	
	
	// MARK: Properties
	let simpleCell = "cell"
	let detailsCell = "details"
	
	
	// MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


// MARK: - Table view data source
extension SettingsTableViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let sect = Section(rawValue: section) else {
			return 0
		}
		
		switch sect {
		case .applicationInfo:
			return 1
			
		case .utilities:
			return 1
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return Section(rawValue: section)?.localized
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let section = Section(rawValue: indexPath.section) else {
			return UITableViewCell(style: .default, reuseIdentifier: nil)
		}
		
		let cell: UITableViewCell
		
		switch section {
		case .utilities:
			if let c = tableView.dequeueReusableCell(withIdentifier: simpleCell) {
				cell = c
			} else {
				cell = UITableViewCell(style: .value1, reuseIdentifier: simpleCell)
			}
			
			cell.textLabel?.text = Row.qrPassphraseGenerator.localized
			cell.accessoryType = .disclosureIndicator
			
		case .applicationInfo:
			if let c = tableView.dequeueReusableCell(withIdentifier: detailsCell) {
				cell = c
			} else {
				cell = UITableViewCell(style: .value1, reuseIdentifier: detailsCell)
			}
			
			cell.textLabel?.text = Row.version.localized
			cell.detailTextLabel?.text = AdamantUtilities.applicationVersion
		}
		
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let section = Section(rawValue: indexPath.section) else {
			return
		}
		
		switch section {
		case .utilities:
			performSegue(withIdentifier: qrGeneratorSegue, sender: nil)
			
		case .applicationInfo:
			dialogService.presentShareAlertFor(string: AdamantUtilities.applicationVersion,
											   types: [.copyToPasteboard],
											   excludedActivityTypes: nil,
											   animated: true) {
				tableView.deselectRow(at: indexPath, animated: true)
			}
		}
		
	}
}
