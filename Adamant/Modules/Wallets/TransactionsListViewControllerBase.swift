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
    enum transactionList {
        static var title: String {
            String.localized("TransactionListScene.Title", comment: "TransactionList: scene title")
        }
        static var toChat: String {
            String.localized("TransactionListScene.ToChat", comment: "TransactionList: To Chat button")
        }
        static var startChat: String {
            String.localized("TransactionListScene.StartChat", comment: "TransactionList: Start Chat button")
        }
        static var notFound: String {
            String.localized("TransactionListScene.Error.NotFound", comment: "TransactionList: 'Transactions not found' message.")
        }
        static var noTransactionYet: String {
            String.localized("TransactionListScene.NoTransactionYet", comment: "TransactionList: 'No Transaction Yet' message.")
        }
    }
}

private typealias TransactionsDiffableDataSource = UITableViewDiffableDataSource<Int, SimpleTransactionDetails>

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
    
    var subscriptions = Set<AnyCancellable>()
    var transactions: [SimpleTransactionDetails] = []
    private(set) lazy var loadingView = LoadingView()
    
    private var limit = 25
    private var offset = 0
    
    private lazy var dataSource = TransactionsDiffableDataSource(tableView: tableView, cellProvider: makeCell)
    
    var currencySymbol: String { walletService.tokenSymbol }
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = String.adamant.transactionList.title
        emptyLabel.text = String.adamant.transactionList.noTransactionYet
        
        update(walletService.getLocalTransactionHistory())
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
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: cellIdentifierFull)
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: cellIdentifierCompact)
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.tableHeaderView = UIView()
    }
    
    @MainActor
    func update(_ transactions: [TransactionDetails]) {
        let transactions = transactions.map {
            SimpleTransactionDetails($0)
        }
        
        update(transactions)
    }
    
    @MainActor
    func update(_ transactions: [SimpleTransactionDetails]) {
        self.transactions = transactions.sorted(
            by: { ($0.dateValue ?? Date()) > ($1.dateValue ?? Date()) }
        )

        let list = self.transactions
        var snapshot = NSDiffableDataSourceSnapshot<Int, SimpleTransactionDetails>()
        snapshot.appendSections([.zero])
        snapshot.appendItems(list)
        snapshot.reconfigureItems(list)
        dataSource.apply(snapshot, animatingDifferences: false)
        
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
    
    private func makeCell(
        tableView: UITableView,
        indexPath: IndexPath,
        model: SimpleTransactionDetails
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifierCompact, for: indexPath) as! TransactionTableViewCell
        
        cell.accessoryType = .disclosureIndicator
        cell.separatorInset = indexPath.row == transactions.count - 1
        ? .zero
        : UITableView.defaultTransactionsSeparatorInset
        
        cell.currencySymbol = currencySymbol
        cell.transaction = model
        return cell
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
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension TransactionsListViewControllerBase: UITableViewDelegate {
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
        case .notInitiated, .inconsistent, .noNetwork, .noNetworkFinal, .pending, .registered:
            return .adamant.alert
        case .success: return .adamant.secondary
        }
    }
}
