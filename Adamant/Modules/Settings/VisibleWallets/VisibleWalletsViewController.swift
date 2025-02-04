//
//  VisibleWalletsViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import CommonKit
import Combine

// MARK: - Localization
extension String.adamant {
    enum visibleWallets {
        static var title: String {
            String.localized("VisibleWallets.Title", comment: "Visible Wallets page: scene title")
        }
        static var resetAlertTitle: String {
            String.localized("VisibleWallets.ResetListAlert", comment: "VisibleWallets: Reset wallets alert title")
        }
        static var reset: String {
            String.localized("NodesList.ResetButton", comment: "NodesList: 'Reset' button")
        }
    }
}

final class VisibleWalletsViewController: KeyboardObservingViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(VisibleWalletsTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.register(VisibleWalletsResetTableViewCell.self, forCellReuseIdentifier: cellResetIdentifier)
        tableView.rowHeight = 50
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setEditing(true, animated: true)
        tableView.allowsSelectionDuringEditing = true
        tableView.refreshControl = refreshControl
        return tableView
    }()
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = true
        return controller
    }()
    
    // MARK: - Dependencies
    
    var visibleWalletsService: VisibleWalletsService
    var accountService: AccountService
    
    // MARK: - Properties
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        refreshControl.addTarget(self, action: #selector(updateBalances), for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    
    private let cellIdentifier = "cell"
    private let cellResetIdentifier = "cellReset"
    private var filteredWallets: [WalletCoreProtocol]?
    private var wallets: [WalletCoreProtocol] = []
    private var previousAppState: UIApplication.State?
    private var subscriptions = Set<AnyCancellable>()
    // MARK: - Lifecycle
    
    init(visibleWalletsService: VisibleWalletsService, accountService: AccountService) {
        self.visibleWalletsService = visibleWalletsService
        self.accountService = accountService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        loadWallets()
        setupView()
        addObservers()
        updateBalances()
        setColors()
    }
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
    }
    
    private func addObservers() {
        wallets
            .map { NotificationCenter.default.publisher(for: $0.walletUpdatedNotification, object: $0) }
            .publisher
            .flatMap { $0 }
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            MainActor.assumeIsolatedSafe {
                if let previousAppState = self?.previousAppState,
                   previousAppState == .background {
                    self?.previousAppState = .active
                    self?.updateBalances()
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            MainActor.assumeIsolatedSafe {
                self?.previousAppState = .background
            }
        }
    }
    
    private func loadWallets() {
        wallets = visibleWalletsService.sorted(includeInvisible: true).map { $0.core }
    }
    
    @objc private func updateBalances() {
        refreshControl.endRefreshing()
        NotificationCenter.default.post(name: .AdamantAccountService.forceUpdateAllBalances, object: nil)
    }
    
    private func setupView() {
        navigationItem.title = String.adamant.visibleWallets.title
        navigationItem.searchController = searchController
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .search, target: self, action: #selector(activateSearch))
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
    
    @objc private func activateSearch() {
        if let bar = navigationItem.searchController?.searchBar,
           !bar.isFirstResponder {
            bar.becomeFirstResponder()
        }
    }
    
    private func isInvisible(_ wallet: WalletCoreProtocol) -> Bool {
        return visibleWalletsService.isInvisible(wallet)
    }
    
    private func resetWalletsAction() {
        let alert = UIAlertController(title: String.adamant.visibleWallets.resetAlertTitle, message: nil, preferredStyleSafe: .alert, source: nil)
        alert.addAction(UIAlertAction(title: String.adamant.alert.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(
            title: .adamant.visibleWallets.reset,
            style: .destructive,
            handler: { [weak self] _ in
                self?.visibleWalletsService.reset()
                self?.loadWallets()
                self?.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            }
        ))
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableView
extension VisibleWalletsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        sectionsCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else { return 1 }
        
        if let filtered = filteredWallets {
            return filtered.count
        } else {
            return wallets.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == sectionsCount - 1
            ? UITableView.automaticDimension
            : cellSpacing
    }
    
    // MARK: Cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellResetIdentifier, for: indexPath) as! VisibleWalletsResetTableViewCell
            cell.selectionStyle = .default
            cell.backgroundColor = UIColor.adamant.cellColor
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? VisibleWalletsTableViewCell else {
            return UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        cell.selectionStyle = .none
        
        cell.separatorInset = UITableView.defaultSeparatorInset
        let maxCount = filteredWallets?.count ?? wallets.count
        if indexPath.row == maxCount - 1 {
            cell.separatorInset = .zero
        }
        
        let wallet: WalletCoreProtocol
        if let filtered = filteredWallets {
            wallet = filtered[indexPath.row]
        } else {
            wallet = wallets[indexPath.row]
        }
        let isToken = ERC20Token.supportedTokens.contains(where: { token in
            return token.symbol == wallet.tokenSymbol
        })
        
        cell.backgroundColor = UIColor.adamant.cellColor
        cell.title = wallet.tokenName
        cell.caption = !isToken ? "Blockchain" : type(of: wallet).tokenNetworkSymbol
        cell.subtitle = wallet.tokenSymbol
        cell.logoImage = wallet.tokenLogo
        cell.balance = wallet.wallet?.balance
        cell.delegate = self
        cell.isChecked = !isInvisible(wallet)
        cell.unicId = wallet.tokenUnicID
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? VisibleWalletsTableViewCell
        else {
            tableView.deselectRow(at: indexPath, animated: true)
            resetWalletsAction()
            return
        }
        let wallet = wallets[indexPath.row]
        delegateCell(cell, didChangeCheckedStateTo: !isInvisible(wallet))
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 0 else {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard proposedDestinationIndexPath.section == 0 else {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard destinationIndexPath.section == 0 else { return }
        let wallet = wallets.remove(at: sourceIndexPath.row)
        wallets.insert(wallet, at: destinationIndexPath.row)
        visibleWalletsService.setIndexPositionWallets(wallets, includeInvisible: true)
        visibleWalletsService.setIndexPositionWallets(wallets, includeInvisible: false)
        NotificationCenter.default.post(name: Notification.Name.AdamantVisibleWalletsService.visibleWallets, object: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == .zero && filteredWallets == nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? UITableView.automaticDimension : 45
    }
}

// MARK: - AdamantVisibleWalletsCellDelegate
extension VisibleWalletsViewController: AdamantVisibleWalletsCellDelegate {
    func delegateCell(
        _ cell: VisibleWalletsTableViewCell,
        didChangeCheckedStateTo state: Bool
    ) {
        let wallet = wallets.first(where: {
            $0.tokenUnicID == cell.unicId
        })
        
        guard let wallet = wallet else { return }
        
        if !isInvisible(wallet) {
            visibleWalletsService.addToInvisibleWallets(wallet)
        } else {
            visibleWalletsService.removeFromInvisibleWallets(wallet)
        }
        visibleWalletsService.setIndexPositionWallets(wallets, includeInvisible: true)
        visibleWalletsService.setIndexPositionWallets(wallets, includeInvisible: false)
        NotificationCenter.default.post(name: Notification.Name.AdamantVisibleWalletsService.visibleWallets, object: nil)
    }
}

// MARK: - UISearchResultsUpdating
extension VisibleWalletsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let search = searchController.searchBar.text?.lowercased(), search.count > 0 {
            filteredWallets = wallets.filter { wallet in
                return wallet.tokenName.lowercased().contains(search.lowercased()) || wallet.tokenSymbol.lowercased().contains(search.lowercased())
            }
        } else {
            filteredWallets = nil
        }
        
        tableView.reloadData()
    }
}

private let sectionsCount = 2
private let cellSpacing: CGFloat = 10
