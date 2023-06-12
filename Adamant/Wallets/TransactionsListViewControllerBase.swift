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
        refreshControl.tintColor = .adamant.primary
        refreshControl.addTarget(
            self,
            action: #selector(self.handleRefresh),
            for: UIControl.Event.valueChanged
        )
        return refreshControl
    }()
    
    var taskManager = TaskManager()
    
    var isNeedToLoadMoore = true
    var isBusy = true
    
    private(set) lazy var loadingView = LoadingView()
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = String.adamantLocalized.transactionList.title
        emptyLabel.text = String.adamantLocalized.transactionList.noTransactionYet
        
        // MARK: Configure tableView
        let nib = UINib.init(nibName: "TransactionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifierFull)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifierCompact)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.tableHeaderView = UIView()
        
        // MARK: Notifications
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAddressBookService.addressBookUpdated, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.reloadData()
        }
        
        setColors()
        configureLayout()
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
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.backgroundColor
        tableView.backgroundColor = .clear
    }
    
    func configureLayout() {
        view.addSubview(loadingView)
        loadingView.isHidden = true
        
        loadingView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    func updateLoadingView(isHidden: Bool) {
        loadingView.isHidden = isHidden
        if !isHidden {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
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
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return TransactionTableViewCell.cellFooterLoadingCompact
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !isBusy,
              isNeedToLoadMoore,
              tableView.numberOfRows(inSection: .zero) - indexPath.row < 3
        else {
            return
        }

        bottomIndicatorView().startAnimating()
        loadData(silent: true)
    }
    
    @objc func handleRefresh() {
        
    }
    
    func loadData(silent: Bool) {
        
    }
    
    func reloadData() {
        
    }
    
    var currencySymbol: String?
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension TransactionsListViewControllerBase: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: Cells
    
    func configureCell(
        _ cell: TransactionTableViewCell,
        isOutgoing: Bool,
        partnerId: String,
        partnerName: String?,
        amount: Decimal,
        date: Date?
    ) {
        cell.backgroundColor = .clear
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
            cell.addressLabel.lineBreakMode = .byTruncatingMiddle
            
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
    
    func bottomIndicatorView() -> UIActivityIndicatorView {
        var activityIndicatorView = UIActivityIndicatorView()
        
        guard tableView.tableFooterView == nil else {
            return activityIndicatorView
        }
        
        let indicatorFrame = CGRect(
            x: .zero,
            y: .zero,
            width: tableView.bounds.width,
            height: TransactionTableViewCell.cellFooterLoadingCompact
        )
        activityIndicatorView = UIActivityIndicatorView(frame: indicatorFrame)
        activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        activityIndicatorView.style = .medium
        activityIndicatorView.color = .lightGray
        activityIndicatorView.hidesWhenStopped = true
        
        tableView.tableFooterView = activityIndicatorView
        
        return activityIndicatorView
    }
    
    func stopBottomIndicator() {
        guard let activityIndicatorView = tableView.tableFooterView as? UIActivityIndicatorView else {
            return
        }
        
        activityIndicatorView.stopAnimating()
        tableView.tableFooterView = nil
    }
}
