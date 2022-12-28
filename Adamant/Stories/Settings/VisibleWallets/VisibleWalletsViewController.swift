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
        static let resetAlertTitle = NSLocalizedString("VisibleWallets.ResetListAlert", comment: "VisibleWallets: Reset wallets alert title")
        static let reset = NSLocalizedString("NodesList.ResetButton", comment: "NodesList: 'Reset' button")
        
        private init() { }
    }
}

class VisibleWalletsViewController: UIViewController {
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
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
    private let cellResetIdentifier = "cellReset"
    private var filteredWallets: [WalletService]?
    private var wallets: [WalletService] = []
    private var previousAppState: UIApplication.State?
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadWallets()
        setupView()
        addObservers()
        updateBalances()
    }
    
    private func addObservers() {
        for wallet in wallets {
            let notification = wallet.walletUpdatedNotification
            let callback: ((Notification) -> Void) = { [weak self] _ in
                guard let self = self else { return }
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
    
    private func loadWallets() {
        wallets = accountService.wallets
        
        // sort manually
        visibleWalletsService.getIndexPositionWallets(includeInvisible: true).sorted { $0.value < $1.value }.forEach { tokenUnicID, newIndex in
            guard let index = wallets.firstIndex(where: { wallet in
                return wallet.tokenUnicID == tokenUnicID
            }) else { return }
            let wallet = wallets.remove(at: index)
            wallets.insert(wallet, at: newIndex)
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
    
    private func resetWalletsAction() {
        let alert = UIAlertController(title: String.adamantLocalized.visibleWallets.resetAlertTitle, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(
            title: .adamantLocalized.visibleWallets.reset,
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else { return 1 }
        
        if let filtered = filteredWallets {
            return filtered.count
        } else {
            return wallets.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return section == 0 ? nil : UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: Cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellResetIdentifier, for: indexPath) as! VisibleWalletsResetTableViewCell
            cell.selectionStyle = .default
            return cell
        }
        
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
        guard let cell = tableView.cellForRow(at: indexPath) as? VisibleWalletsTableViewCell else {
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
        guard indexPath.section == 0 else {
            return false
        }
        if filteredWallets != nil {
            return false
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == 0 else {
            return 45
        }
        
        return UITableView.automaticDimension
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
