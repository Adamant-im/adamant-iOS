//
//  VisibleWalletsViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - Localization
extension String.adamantLocalized {
    struct visibleWallets {
        static let title = NSLocalizedString("VisibleWallets.Title", comment: "Visible Wallets page: scene title")
        
        private init() { }
    }
}

class VisibleWalletsViewController: UIViewController {
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(VisibleWalletsTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = 50
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setEditing(true, animated: true)
        tableView.allowsSelectionDuringEditing = true
        tableView.refreshControl = refreshControl
        return tableView
    }()
    
    lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = true
        return controller
    }()
    
    // MARK: - Dependencies
    
    var visibleWalletsService: VisibleWalletsService!
    var accountService: AccountService!
    
    // MARK: - Properties
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        refreshControl.addTarget(self, action: #selector(updateBalances), for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    
    private let cellIdentifier = "cell"
    private var filteredWallets: [WalletService]?
    private var wallets: [WalletService] = []
    private var previousAppState: UIApplication.State?
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wallets = accountService.wallets
        
        // sort manually
        visibleWalletsService.getIndexPositionWallets(includeInvisible: true).sorted { $0.value < $1.value }.forEach { tokenUnicID, newIndex in
            guard let index = wallets.firstIndex(where: { wallet in
                return wallet.tokenUnicID == tokenUnicID
            }) else { return }
            let wallet = wallets.remove(at: index)
            wallets.insert(wallet, at: newIndex)
        }
        
        setupView()
        addObservers()
        updateBalances()
    }
    
    private func addObservers() {
        for wallet in wallets {
            let notification = wallet.walletUpdatedNotification
            let callback: ((Notification) -> Void) = { [weak self] _ in
                guard let self = self else { return }
                print("updating")
                self.tableView.reloadData()
            }

            NotificationCenter.default.addObserver(forName: notification,
                                                   object: wallet,
                                                   queue: OperationQueue.main,
                                                   using: callback)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            if let previousAppState = self?.previousAppState,
               previousAppState == .background {
                self?.previousAppState = .active
                self?.updateBalances()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.previousAppState = .background
        }
    }
    
    @objc private func updateBalances() {
        refreshControl.endRefreshing()
        NotificationCenter.default.post(name: .AdamantAccountService.forceUpdateBalance, object: nil)
    }
    
    private func setupView() {
        navigationItem.title = String.adamantLocalized.visibleWallets.title
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
    
    private func isInvisible(_ wallet: WalletService) -> Bool {
        return visibleWalletsService.isInvisible(wallet)
    }
}

// MARK: - UITableView
extension VisibleWalletsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filtered = filteredWallets {
            return filtered.count
        } else {
            return wallets.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: Cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? VisibleWalletsTableViewCell else {
            return UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        cell.selectionStyle = .none
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        let maxCount = filteredWallets?.count ?? wallets.count
        if indexPath.row == maxCount - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        let wallet: WalletService
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
        cell.caption = !isToken ? "Blockchain" : wallet.tokenNetworkSymbol
        cell.subtitle = wallet.tokenSymbol
        cell.logoImage = wallet.tokenLogo
        cell.balance = wallet.wallet?.balance
        cell.delegate = self
        cell.isChecked = !isInvisible(wallet)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? VisibleWalletsTableViewCell else { return }
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
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let wallet = wallets.remove(at: sourceIndexPath.row)
        wallets.insert(wallet, at: destinationIndexPath.row)
        visibleWalletsService.setIndexPositionWallets(wallets, includeInvisible: true)
        visibleWalletsService.setIndexPositionWallets(wallets, includeInvisible: false)
        NotificationCenter.default.post(name: Notification.Name.AdamantVisibleWalletsService.visibleWallets, object: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if filteredWallets != nil {
            return false
        } else {
            return true
        }
    }
}

// MARK: - AdamantVisibleWalletsCellDelegate
extension VisibleWalletsViewController: AdamantVisibleWalletsCellDelegate {
    func delegateCell(_ cell: VisibleWalletsTableViewCell, didChangeCheckedStateTo state: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let wallet = wallets[indexPath.row]
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
