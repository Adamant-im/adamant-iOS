//
//  TransactionsListViewControllerBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData
import CommonKit
import Combine

extension String.adamant {
    struct transactionList {
        static let title = String.localized("TransactionListScene.Title", comment: "TransactionList: scene title")
        static let toChat = String.localized("TransactionListScene.ToChat", comment: "TransactionList: To Chat button")
        static let startChat = String.localized("TransactionListScene.StartChat", comment: "TransactionList: Start Chat button")
        static let notFound = String.localized("TransactionListScene.Error.NotFound", comment: "TransactionList: 'Transactions not found' message.")
        static let noTransactionYet = String.localized("TransactionListScene.NoTransactionYet", comment: "TransactionList: 'No Transaction Yet' message.")
        
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
    
    // MARK: - Dependencies
    
    var walletService: WalletService!
    var dialogService: DialogService!
    
    // MARK: - Proprieties
    
    var taskManager = TaskManager()
    
    var isNeedToLoadMoore = true
    var isBusy = false
    
    var transactions: [CoinTransaction] = []
    private(set) lazy var loadingView = LoadingView()
    
    private var subscriptions = Set<AnyCancellable>()
    private var limit = 25
    private var offset = 0
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = String.adamant.transactionList.title
        emptyLabel.text = String.adamant.transactionList.noTransactionYet
        
        transactions = walletService.getLocalTransactionHistory()
        configureTableView()
        setColors()
        configureLayout()
        addObservers()
        handleRefresh()
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
    
    func addObservers() {
        NotificationCenter.default
            .publisher(for: .AdamantAddressBookService.addressBookUpdated, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.reloadData()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.reloadData()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedIn, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.reloadData()
            }
            .store(in: &subscriptions)
        
        walletService.transactionsPublisher
            .receive(on: OperationQueue.main)
            .sink { [weak self] transactions in
                self?.update(transactions)
            }
            .store(in: &subscriptions)
        
        walletService.hasMoreOldTransactionsPublisher
            .sink { [weak self] isNeedToLoadMoore in
                self?.isNeedToLoadMoore = isNeedToLoadMoore
            }
            .store(in: &subscriptions)
    }
    
    func configureTableView() {
        let nib = UINib.init(nibName: "TransactionTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifierFull)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifierCompact)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.tableHeaderView = UIView()
    }
    
    @MainActor
    func update(_ transactions: [CoinTransaction]) {
        self.transactions = transactions.sorted(by: {
            (($0.date ?? NSDate()) as Date) > (($1.date ?? NSDate()) as Date)
        })
        self.tableView.reloadData()
        
        guard !isBusy else { return }
        self.updateLoadingView(isHidden: true)
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
    
    func presentLoadingViewIfNeeded() {
        guard transactions.count == 0 else { return }
        updateLoadingView(isHidden: false)
    }
    
    func updateLoadingView(isHidden: Bool) {
        loadingView.isHidden = isHidden
        if !isHidden {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }
    
    @MainActor
    func loadData(silent: Bool) {
        loadData(offset: offset, silent: true)
    }
    
    @MainActor
    func loadData(offset: Int, silent: Bool) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            do {
                let count = try await walletService.loadTransactions(
                    offset: offset,
                    limit: limit
                )
                self.offset += count
            } catch {
                isNeedToLoadMoore = false
                
                if !silent {
                    dialogService.showRichError(error: error)
                }
            }
            
            isBusy = false
            emptyLabel.isHidden = self.transactions.count > 0
            stopBottomIndicator()
            refreshControl.endRefreshing()
            tableView.reloadData()
            updateLoadingView(isHidden: true)
        }.stored(in: taskManager)
    }
    
    // MARK: - To override
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionTableViewCell.cellHeightCompact
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifierCompact, for: indexPath) as? TransactionTableViewCell else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let transaction = transactions[indexPath.row]
        
        cell.accessoryType = .disclosureIndicator
        cell.separatorInset = indexPath.row == transactions.count - 1
        ? .zero
        : UITableView.defaultTransactionsSeparatorInset
        
        let partnerId = transaction.isOutgoing
        ? transaction.recipientId
        : transaction.senderId
        
        let transactionType: TransactionTableViewCell.TransactionType
        if transaction.recipientId == transaction.senderId {
            transactionType = .myself
        } else if transaction.isOutgoing {
            transactionType = .outcome
        } else {
            transactionType = .income
        }
        
        configureCell(
            cell,
            transactionType: transactionType,
            transactionStatus: transaction.transactionStatus,
            partnerId: partnerId ?? "",
            partnerName: nil,
            amount: (transaction.amount ?? 0).decimalValue,
            date: transaction.date as? Date
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
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
        presentLoadingViewIfNeeded()
        emptyLabel.isHidden = true
        loadData(offset: .zero, silent: true)
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
        transactionType: TransactionTableViewCell.TransactionType,
        transactionStatus: TransactionStatus?,
        partnerId: String,
        partnerName: String?,
        amount: Decimal,
        date: Date?
    ) {
        cell.backgroundColor = .clear
        cell.accountLabel.tintColor = UIColor.adamant.primary
        cell.ammountLabel.tintColor = UIColor.adamant.primary
        
        cell.dateLabel.textColor = transactionStatus?.color ?? .adamant.secondary
        
        switch transactionStatus {
        case .success, .inconsistent, .registered:
            if let date = date {
                cell.dateLabel.text = date.humanizedDateTime()
            } else {
                cell.dateLabel.text = nil
            }
        case .failed:
            cell.dateLabel.text = TransactionStatus.failed.localized
        default:
            cell.dateLabel.text = TransactionStatus.pending.localized
        }
        
        cell.transactionType = transactionType
        
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

// MARK: - TransactionStatus UI
private extension TransactionStatus {
    var color: UIColor {
        switch self {
        case .failed: return .adamant.danger
        case .notInitiated, .inconsistent, .noNetwork, .noNetworkFinal, .pending: return .adamant.alert
        case .success, .registered: return .adamant.secondary
        }
    }
}
