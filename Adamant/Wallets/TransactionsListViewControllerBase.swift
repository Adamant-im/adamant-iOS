//
//  TransactionsListViewControllerBase.swift
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
        static let notFound = NSLocalizedString("TransactionListScene.Error.NotFound", comment: "TransactionList: 'Transactions not found' message.")
        static let noTransactionYet = NSLocalizedString("TransactionListScene.NoTransactionYet", comment: "TransactionList: 'No Transaction Yet' message.")
        
    }
}

// Extensions for a generic classes is limited, so delegates implemented right in class declaration
class TransactionsListViewControllerBase: UIViewController {
    let cellIdentifierFull = "cf"
    let cellIdentifierCompact = "cc"
    
    internal lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        navigationItem.title = String.adamantLocalized.transactionList.title
        emptyLabel.text = String.adamantLocalized.transactionList.noTransactionYet
        
        // MARK: Configure tableView
        let nib = UINib.init(nibName: "TransactionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifierFull)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifierCompact)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        
        // MARK: Notifications
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAddressBookService.addressBookUpdated, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.emptyLabel.isHidden = true
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
        
        if tableView.isEditing {
            tableView.setEditing(false, animated: false)
        }
    }
    
    
    // MARK: - To override
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionTableViewCell.cellHeightCompact
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: "cell")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    @objc internal func handleRefresh(_ refreshControl: UIRefreshControl) {
        
    }
    
    func reloadData() {
        
    }
    
    var currencySymbol: String? = nil
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension TransactionsListViewControllerBase: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: Cells
    
    func configureCell(_ cell: TransactionTableViewCell,
                       isOutgoing: Bool,
                       partnerId: String,
                       partnerName: String?,
                       amount: Decimal,
                       date: Date?) {
        cell.accountLabel.tintColor = UIColor.adamant.primary
        cell.ammountLabel.tintColor = UIColor.adamant.primary
        cell.dateLabel.tintColor = UIColor.adamant.secondary
        
        if isOutgoing {
            cell.transactionType = .outcome
        } else {
            cell.transactionType = .income
        }
        
        if let partnerName = partnerName {
            cell.accountLabel.text = partnerName
            cell.addressLabel.text = partnerId
            
            if cell.addressLabel.isHidden {
                cell.addressLabel.isHidden = false
            }
        } else {
            cell.accountLabel.text = partnerId
            
            if !cell.addressLabel.isHidden {
                cell.addressLabel.isHidden = true
            }
        }
        
        cell.ammountLabel.text = AdamantBalanceFormat.full.format(amount, withCurrencySymbol: currencySymbol)
        
        if let date = date {
            cell.dateLabel.text = date.humanizedDateTime()
        } else {
            cell.dateLabel.text = nil
        }
    }
}
