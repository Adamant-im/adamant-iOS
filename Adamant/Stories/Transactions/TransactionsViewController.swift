//
//  TransactionsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData

extension String.adamantLocalized {
	struct transactionList {
		static let title = NSLocalizedString("TransactionListScene.Title", comment: "TransactionList: scene title")
        static let toChat = NSLocalizedString("TransactionListScene.ToChat", comment: "TransactionList: To Chat button")
        static let startChat = NSLocalizedString("TransactionListScene.StartChat", comment: "TransactionList: Start Chat button")
	}
}

class TransactionsViewController: UIViewController {
    let cellIdentifier = "cell"
    let cellHeight: CGFloat = 90.0
    
    internal lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.adamantPrimary
        
        return refreshControl
    }()
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String.adamantLocalized.transactionList.title
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib.init(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.addSubview(self.refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
        
        if tableView.isEditing {
            tableView.setEditing(false, animated: false)
        }
    }
    
    @objc internal func handleRefresh(_ refreshControl: UIRefreshControl) {
        
    }
    
    internal func currentAddress() -> String {
        return ""
    }
}

// MARK: - UITableView Cells
extension TransactionsViewController {
    internal func configureCell(_ cell: TransactionTableViewCell, for transfer: TransactionDetailsProtocol) {
        cell.accountLabel.tintColor = UIColor.adamantPrimary
        cell.ammountLabel.tintColor = UIColor.adamantPrimary
        cell.dateLabel.tintColor = UIColor.adamantSecondary
        cell.avatarImageView.tintColor = UIColor.adamantPrimary
        
        if transfer.isOutgoing(currentAddress()) {
            cell.transactionType = .outcome
            cell.accountLabel.text = transfer.recipientAddress
        } else {
            cell.transactionType = .income
            cell.accountLabel.text = transfer.senderAddress
        }
        
        cell.ammountLabel.text = transfer.formattedAmount()
        
        cell.dateLabel.text = transfer.sentDate.humanizedDateTime()
    }
}

// MARK: - UITableView
extension TransactionsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: "cell")
    }
    
}
