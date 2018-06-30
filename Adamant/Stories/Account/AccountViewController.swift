//
//  AccountViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class AccountViewController: FormViewController {
	// MARK: - Rows & Sections
	private enum Sections {
		case account, wallet, security, application
		
		var tag: String {
			switch self {
			case .account: return "acc"
			case .wallet: return "wllt"
			case .security: return "scrt"
			case .application: return "app"
			}
		}
		
		var localized: String {
			switch self {
			case .account: return ""
			case .wallet: return "Wallet"
			case .security: return "Security"
			case .application: return "Application"
			}
		}
	}
	
	private enum Rows {
		case account
		case transfers, sendTokens, buyTokens, freeTokens // Wallet
		case stayLoggedIn, notifications, generateQr, logout // Security
		case nodes, about // Application
		
		var tag: String {
			switch self {
			case .account: return "acc"
			case .transfers: return "trsfrs"
			case .sendTokens: return "sndTkns"
			case .buyTokens: return "bTkns"
			case .freeTokens: return "frrTkns"
			case .stayLoggedIn: return "stIn"
			case .notifications: return "ntfctns"
			case .generateQr: return "gnrtQr"
			case .logout: return "lgt"
			case .nodes: return "nds"
			case .about: return "bt"
			}
		}
		
		var localized: String {
			switch self {
			case .account: return ""
			case .transfers: return "Transfers"
			case .sendTokens: return "Send Tokens"
			case .buyTokens: return "Buy Tokens"
			case .freeTokens: return "Free Tokens"
			case .stayLoggedIn: return "Stay Logged In"
			case .notifications: return "Notifications"
			case .generateQr: return "Generate Qr"
			case .logout: return "Logout"
			case .nodes: return "Nodes"
			case .about: return "About"
			}
		}
	}
	
	// MARK: - Wallets
	
	
	// MARK: - Properties
	
	let walletCellIdentifier = "wllt"
	private (set) var accountHeaderView: AccountHeaderView!
	var wallets: [Wallet]? {
		didSet {
			accountHeaderView?.walletCollectionView.reloadData()
		}
	}
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()

		// MARK: Header&Footer
		guard let header = UINib(nibName: "AccountHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? AccountHeaderView else {
			fatalError("Can't load AccountHeaderView")
		}
		
		accountHeaderView = header
		accountHeaderView.walletCollectionView.delegate = self
		accountHeaderView.walletCollectionView.dataSource = self
		accountHeaderView.walletCollectionView.register(UINib(nibName: "WalletCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: walletCellIdentifier)
		
		tableView.tableHeaderView = header
		
		if let footer = UINib(nibName: "AccountFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			tableView.tableFooterView = footer
		}
		
		
		// MARK: Wallet
		
		form +++ Section(Sections.wallet.localized) {
			$0.tag = Sections.wallet.tag
		}
		
		// Transfers
		<<< LabelRow() {
			$0.title = Rows.transfers.localized
			$0.tag = Rows.transfers.tag
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
			
		// Send Tokens
		<<< LabelRow() {
			$0.title = Rows.sendTokens.localized
			$0.tag = Rows.sendTokens.tag
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
		// Buy tokens
		<<< LabelRow() {
			$0.title = Rows.buyTokens.localized
			$0.tag = Rows.buyTokens.tag
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
		// Buy tokens
		<<< LabelRow() {
			$0.title = Rows.freeTokens.localized
			$0.tag = Rows.freeTokens.tag
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
		
		// MARK: Security
		+++ Section(Sections.security.localized) {
			$0.tag = Sections.security.tag
		}
		
		// Stay logged in
		<<< LabelRow() {
			$0.title = Rows.stayLoggedIn.localized
			$0.tag = Rows.stayLoggedIn.tag
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
			
		// Notifications
		<<< LabelRow() {
			$0.title = Rows.notifications.localized
			$0.tag = Rows.notifications.tag
			
			// TODO: Value
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
			
		// Generate QR
		<<< LabelRow() {
			$0.title = Rows.generateQr.localized
			$0.tag = Rows.generateQr.tag
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
		
		// MARK: Application
		+++ Section(Sections.application.localized) {
			$0.tag = Sections.application.tag
		}
		
		// Node list
		<<< LabelRow() {
			$0.title = Rows.nodes.localized
			$0.tag = Rows.nodes.tag
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
		// About
		<<< LabelRow() {
			$0.title = Rows.about.localized
			$0.tag = Rows.about.tag
		}.cellSetup({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
		wallets = [.adamant(balance: Decimal(floatLiteral: 100.001)), .etherium(balance: Decimal(floatLiteral: 105.5001))]
    }
}


// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension AccountViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let wallets = wallets else {
			return 0
		}
		
		return wallets.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: walletCellIdentifier, for: indexPath) as? WalletCollectionViewCell else {
			fatalError("Can't dequeue wallet cell")
		}
		
		guard let wallet = wallets?[indexPath.row] else {
			fatalError("Wallets collectionView: Out of bounds row")
		}
		
		cell.currencyImageView.image = wallet.currencyLogo
		cell.currencySymbolLabel.text = wallet.currencySymbol
		
		switch wallet {
		case .adamant(let balance), .etherium(let balance):
			cell.balanceLabel.text = AdamantUtilities.currencyFormatter.string(from: balance as NSNumber)
		}
		
		// TODO: check current selected cell
		cell.setSelected(false, animated: false)
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	// Flow delegate
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 110, height: 110)
	}
}
