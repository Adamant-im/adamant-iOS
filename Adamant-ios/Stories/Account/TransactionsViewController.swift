//
//  TransactionsViewController.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class TransactionsViewController: UIViewController {

	// MARK: - Dependencies
	var cellFactory: CellFactory!
	var apiService: ApiService!
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.register(cellFactory.nib(for: .TransactionCell), forCellReuseIdentifier: SharedCell.TransactionCell.cellIdentifier)
		tableView.dataSource = self
		tableView.delegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
}


// MARK: - UITableViewDataSource
extension TransactionsViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// TODO: Get data
		return 0
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return SharedCell.TransactionCell.defaultRowHeight
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: SharedCell.TransactionCell.cellIdentifier, for: indexPath) as? TransactionTableViewCell else {
			let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
			cell.textLabel!.text = "failed to get cell"
			return cell
		}
		
		// TODO: Configure cell
		
		return cell
	}
}


// MARK: - UITableViewDelegate
extension TransactionsViewController: UITableViewDelegate {
	
}
