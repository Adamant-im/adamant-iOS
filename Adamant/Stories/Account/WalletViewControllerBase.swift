//
//  WalletViewControllerBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class WalletViewControllerBase: FormViewController, WalletViewController {
	// MARK: - Rows
	enum BaseRows {
		case address, balance, send
		
		var tag: String {
			switch self {
			case .address: return "a"
			case .balance: return "b"
			case .send: return "s"
			}
		}
		
		var localized: String {
			switch self {
			case .address: return "Адрес"
			case . balance: return "Баланс"
			case .send: return "Отправить"
			}
		}
	}
	
	private let cellIdentifier = "cell"
	
	// MARK: - Properties, WalletViewController
	
	var viewController: UIViewController { return self }
	var height: CGFloat { return tableView.frame.origin.y + tableView.contentSize.height }
	
	var service: WalletService?
	
	// MARK: - IBOutlets
	
	@IBOutlet weak var walletTitleLabel: UILabel!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let section = Section()
		
		// MARK: Address
		let addressRow = LabelRow() {
			$0.tag = BaseRows.address.tag
			$0.title = BaseRows.address.localized
			$0.cell.selectionStyle = .gray
			
			if let wallet = service?.wallet {
				$0.value = wallet.address
			}
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}.onCellSelection { (_, _) in
			print("Share address")
		}
		
		section.append(addressRow)
		
		// MARK: Balance
		let balanceRow = LabelRow() {
			$0.tag = BaseRows.balance.tag
			$0.title = BaseRows.balance.localized
			
			if let wallet = service?.wallet {
				$0.value = AdamantBalanceFormat.full.format(balance: wallet.balance)
			}
		}
		
		if service is WalletWithTransfers {
			balanceRow.cell.selectionStyle = .gray
			balanceRow.cellUpdate { (cell, _) in
				cell.accessoryType = .disclosureIndicator
			}.onCellSelection { [weak self] (_, _) in
				guard let service = self?.service as? WalletWithTransfers else {
					return
				}
				
				service.showTransfers()
			}
		}
		
		section.append(balanceRow)
		
		// MARK: Send
		if service is WalletWithSend {
			let sendRow = LabelRow() {
				$0.tag = BaseRows.send.tag
				$0.title = BaseRows.send.localized
				$0.cell.selectionStyle = .gray
			}.cellUpdate { (cell, _) in
				cell.accessoryType = .disclosureIndicator
			}.onCellSelection { [weak self] (_, _) in
				guard let service = self?.service as? WalletWithSend else {
					return
				}
				
				service.showTransfer(recipient: nil)
			}
			
			section.append(sendRow)
		}
		
		
		form.append(section)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	override func viewDidLayoutSubviews() {
		NotificationCenter.default.post(name: Notification.Name.WalletViewController.heightUpdated, object: self)
	}
}
