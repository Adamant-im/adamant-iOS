//
//  AccountViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

fileprivate extension Wallet {
	var sectionTag: String {
		switch self {
		case .adamant: return "s_adm"
		case .etherium: return "s_eth"
		}
	}
	
	var sectionTitle: String {
		switch self {
		case .adamant: return "ADAMANT Wallet"
		case .etherium: return "Etherium Wallet"
		}
	}
}

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
		case balance, sendTokens, buyTokens, freeTokens // Wallet
		case stayLoggedIn, notifications, generateQr, logout // Security
		case nodes, about // Application
		
		var tag: String {
			switch self {
			case .account: return "acc"
			case .balance: return "blnc"
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
			case .balance: return "Balance"
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
	var selectedWalletIndex: Int = 0
	
	// MARK: - Properties
	
	let walletCellIdentifier = "wllt"
	private (set) var accountHeaderView: AccountHeaderView!
	var wallets: [Wallet]? {
		didSet {
			selectedWalletIndex = 0
			accountHeaderView?.walletCollectionView.reloadData()
		}
	}
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationController?.setNavigationBarHidden(true, animated: false)
		
		wallets = [.adamant(balance: Decimal(floatLiteral: 100.001)), .etherium]

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
		
		
		// MARK: Wallets
		if let wallets = wallets {
			for (walletIndex, wallet) in wallets.enumerated() {
				let section = createSectionFor(wallet: wallet)
				
				section.hidden = Condition.function([], { [weak self] _ -> Bool in
					guard let selectedIndex = self?.selectedWalletIndex else {
						return true
					}
					
					return walletIndex != selectedIndex
				})
				
				form.append(section)
			}
		}
		
		
		// MARK: Security
		form +++ Section(Sections.security.localized) {
			$0.tag = Sections.security.tag
		}
		
		// Stay logged in
		<<< LabelRow() {
			$0.title = Rows.stayLoggedIn.localized
			$0.tag = Rows.stayLoggedIn.tag
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
			
		// Notifications
		<<< LabelRow() {
			$0.title = Rows.notifications.localized
			$0.tag = Rows.notifications.tag
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
			
			// TODO: Value
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
			
		// Generate QR
		<<< LabelRow() {
			$0.title = Rows.generateQr.localized
			$0.tag = Rows.generateQr.tag
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
		}.cellUpdate({ (cell, _) in
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
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ (_, _) in
			let viewController = UIViewController()
			viewController.view.backgroundColor = UIColor.white
			self.navigationController?.pushViewController(viewController, animated: true)
		})
		
		// About
		<<< LabelRow() {
			$0.title = Rows.about.localized
			$0.tag = Rows.about.tag
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		})
		
		form.allRows.forEach { $0.baseCell.imageView?.tintColor = UIColor.adamantSecondary; }
		
		accountHeaderView.walletCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
	}
	
	
	// TableView configuration
	
	override func insertAnimation(forSections sections: [Section]) -> UITableViewRowAnimation {
		return .fade
	}
	
	override func deleteAnimation(forSections sections: [Section]) -> UITableViewRowAnimation {
		return .fade
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
		
		cell.tintColor = UIColor.adamantSecondary
		cell.currencyImageView.image = wallet.currencyLogo
		cell.balanceLabel.text = wallet.fomattedShort
		cell.currencySymbolLabel.text = wallet.currencySymbol
		
		let color = UIColor.adamantPrimary
		cell.balanceLabel.textColor = color
		cell.currencySymbolLabel.textColor = color
		
		let font = UIFont.adamantPrimary(size: 17)
		cell.balanceLabel.font = font
		cell.currencySymbolLabel.font = font
		
		cell.setSelected(indexPath.row == selectedWalletIndex, animated: false)
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selectedWalletIndex = indexPath.row
		
		form.allSections.filter { $0.hidden != nil }.forEach { $0.evaluateHidden() }
	}
	
	// Flow delegate
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 110, height: 110)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets.zero
	}
}

// MARK: - Tools
extension AccountViewController {
	func createSectionFor(wallet: Wallet) -> Section {
		let section = Section(wallet.sectionTitle) {
			$0.tag = wallet.sectionTag
		}
		
		switch wallet {
		case .adamant(let balance):
			// Balance
			section <<< LabelRow() {
				$0.title = Rows.balance.localized
				$0.tag = Rows.balance.tag
				$0.value = AdamantUtilities.format(balance: balance)
				$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
			}.cellUpdate({ (cell, _) in
				cell.accessoryType = .disclosureIndicator
			})
			
			// Send Tokens
			<<< LabelRow() {
				$0.title = Rows.sendTokens.localized
				$0.tag = Rows.sendTokens.tag
				$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
			}.cellUpdate({ (cell, _) in
				cell.accessoryType = .disclosureIndicator
			})
			
			// Buy tokens
			<<< LabelRow() {
				$0.title = Rows.buyTokens.localized
				$0.tag = Rows.buyTokens.tag
				$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
			}.cellUpdate({ (cell, _) in
				cell.accessoryType = .disclosureIndicator
			})
			
			// Get free tokens
			<<< LabelRow() {
				$0.title = Rows.freeTokens.localized
				$0.tag = Rows.freeTokens.tag
				$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
			}.cellUpdate({ (cell, _) in
				cell.accessoryType = .disclosureIndicator
			})
			
		case .etherium:
			section <<< LabelRow() {
				$0.title = "Soon..."
			}
		}
		
		return section
	}
}
