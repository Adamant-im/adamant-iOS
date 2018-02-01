//
//  SettingsTableViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
	
	let identifier = "cell"
	lazy var applicationVersion: String = {
		if let infoDictionary = Bundle.main.infoDictionary,
			let version = infoDictionary["CFBundleShortVersionString"] as? String,
			let build = infoDictionary["CFBundleVersion"] as? String {
			return "\(version) (\(build))"
		}
		
		return ""
	}()
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
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
		cell.detailTextLabel?.text = applicationVersion
		
        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		alert.addAction(UIAlertAction(title: "Copy To Pasteboard", style: .default) { _ in
			UIPasteboard.general.string = self.applicationVersion
			tableView.deselectRow(at: indexPath, animated: true)
		})
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
			tableView.deselectRow(at: indexPath, animated: true)
		})
		
		present(alert, animated: true)
	}
}
