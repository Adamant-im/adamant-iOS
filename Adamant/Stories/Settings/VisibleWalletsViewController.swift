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
        static let title = NSLocalizedString("Delegates.Title", comment: "Delegates page: scene title")
        
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
    
    // MARK: - Properties
    
    private let cellIdentifier = "cell"
    private var filteredWallets: [WalletService]?
    private var wallets: [WalletService] = []
    private var invisibleWallets: [String] = []
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let erc20WalletServices = ERC20Token.supportedTokens.map { ERC20WalletService(token: $0) }
        wallets.append(contentsOf: erc20WalletServices)
        
        invisibleWallets = visibleWalletsService.getInvisibleWallets()
        
        setupView()
    }
    
    private func setupView() {
        navigationItem.title = String.adamantLocalized.visibleWallets.title
        navigationItem.searchController = searchController
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .search, target: self, action: #selector(activateSearch))
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    
    @objc private func activateSearch() {
        if let bar = navigationItem.searchController?.searchBar,
           !bar.isFirstResponder {
            bar.becomeFirstResponder()
        }
    }
    
    private func isInvisible(_ wallet: WalletService) -> Bool {
        return invisibleWallets.contains(wallet.tokenContract)
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
    
    // MARK: Cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? VisibleWalletsTableViewCell else {
            return UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        cell.selectionStyle = .none
        
        let wallet = wallets[indexPath.row]
        cell.backgroundColor = UIColor.adamant.cellColor
        cell.title = wallet.tokenName
        cell.caption = wallet.tokenNetworkSymbol
        cell.subtitle = wallet.tokenSymbol
        cell.delegate = self
        cell.isChecked = !isInvisible(wallet)
        return cell
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
            visibleWalletsService.addToInvisibleWallets(wallet.tokenContract)
        } else {
            visibleWalletsService.removeFromInvisibleWallets(wallet.tokenContract)
        }
        invisibleWallets = visibleWalletsService.getInvisibleWallets()
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
