//
//  SettingsTableViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
	
	// MARK: Dependencies
	var dialogService: DialogService!
	
	
	// MARK: Properties
	let identifier = "cell"
	
	
	// MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


// MARK: - Table view data source
extension SettingsTableViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Application info"
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: UITableViewCell
		if let c = tableView.dequeueReusableCell(withIdentifier: identifier) {
			cell = c
		} else {
			cell = UITableViewCell(style: .value1, reuseIdentifier: identifier)
		}
		
		cell.textLabel?.text = "Version"
		cell.detailTextLabel?.text = AdamantUtilities.applicationVersion
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		dialogService.presentShareAlertFor(string: AdamantUtilities.applicationVersion, types: [.copyToPasteboard], animated: true) {
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}
}
