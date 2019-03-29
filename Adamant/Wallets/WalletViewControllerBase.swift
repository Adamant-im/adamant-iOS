//
//  WalletViewControllerBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

extension String.adamantLocalized {
    struct wallets {
        
        private init() {}
    }
}

protocol WalletViewControllerDelegate: class {
    func walletViewControllerSelectedRow(_ viewController: WalletViewControllerBase)
}

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
			case .address: return NSLocalizedString("AccountTab.Row.Address", comment: "Account tab: 'Address' row")
			case .balance: return NSLocalizedString("AccountTab.Row.Balance", comment: "Account tab: Balance row title")
			case .send: return NSLocalizedString("AccountTab.Row.SendTokens", comment: "Account tab: 'Send tokens' button")
			}
		}
	}
	
	private let cellIdentifier = "cell"
	
	
	// MARK: - Dependencies
	
	var dialogService: DialogService!
    var currencyInfoService: CurrencyInfoService!
	
	
	// MARK: - Properties, WalletViewController
	
	var viewController: UIViewController { return self }
	var height: CGFloat { return tableView.frame.origin.y + tableView.contentSize.height }
	
	var service: WalletService?
	
    weak var delegate: WalletViewControllerDelegate?
    
	// MARK: - IBOutlets
	
	@IBOutlet weak var walletTitleLabel: UILabel!
    @IBOutlet weak var initiatingActivityIndicator: UIActivityIndicatorView!
    
    // MARK: Error view
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
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
        }.onCellSelection { [weak self] (cell, row) in
            row.deselect()
			let completion = { [weak self] in
				guard let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow else {
					return
				}
				
				tableView.deselectRow(at: indexPath, animated: true)
			}
			
			if let address = self?.service?.wallet?.address {
                let types: [ShareType]
                let withLogo = self?.includeLogoInQR() ?? false
                
                if let encodedAddress = self?.encodeForQr(address: address) {
                    types = [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: withLogo)]
                } else {
                    types = [.copyToPasteboard, .share]
                }
                
				self?.dialogService.presentShareAlertFor(string: address,
														 types: types,
														 excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                         animated: true, from: cell,
														 completion: completion)
			}
		}
		
		section.append(addressRow)
		
		// MARK: Balance
		let balanceRow = AlertLabelRow() { [weak self] in
			$0.tag = BaseRows.balance.tag
			$0.title = BaseRows.balance.localized
			
			if let alertLabel = $0.cell.alertLabel {
				alertLabel.backgroundColor = UIColor.adamant.primary
				alertLabel.textColor = UIColor.white
				alertLabel.clipsToBounds = true
				alertLabel.textInsets = UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)
				
				if let count = self?.service?.wallet?.notifications, count > 0 {
					alertLabel.text = String(count)
				} else {
					alertLabel.isHidden = true
				}
			}
			
            if let service = self?.service, let wallet = service.wallet {
                let symbol = type(of: service).currencySymbol
                let rate = currencyInfoService.getRate(for: symbol)
                let fiat = wallet.balance.doubleValue * rate
                
                $0.value = AdamantBalanceFormat.full.format(wallet.balance, withCurrencySymbol: symbol) + " (" + AdamantBalanceFormat.short.format(fiat, withCurrencySymbol: currencyInfoService.currentCurrency.symbol) + ")"
            } else {
                $0.value = "0"
            }
		}
        
        NotificationCenter.default.addObserver(forName: Notification.Name.WalletViewController.balanceUpdated, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.updateWalletBalance()
        }
		
		if service is WalletServiceWithTransfers {
			balanceRow.cell.selectionStyle = .gray
			balanceRow.cellUpdate { (cell, _) in
				cell.accessoryType = .disclosureIndicator
            }.onCellSelection { [weak self] (_, row) in
                guard let service = self?.service as? WalletServiceWithTransfers else {
					return
				}
				
                let vc = service.transferListViewController()
                if let split = self?.splitViewController {
                    let details = UINavigationController(rootViewController:vc)
                    split.showDetailViewController(details, sender: self)
                } else {
                    self?.navigationController?.pushViewController(vc, animated: true )
                }
                
                if let vc = self, let delegate = vc.delegate {
                    delegate.walletViewControllerSelectedRow(vc)
                }
			}
		}
		
		section.append(balanceRow)
		
		// MARK: Send
		if service is WalletServiceWithSend {
            let label = sendRowLocalizedLabel()
            
			let sendRow = LabelRow() {
				$0.tag = BaseRows.send.tag
				$0.title = label
				$0.cell.selectionStyle = .gray
			}.cellUpdate { (cell, _) in
				cell.accessoryType = .disclosureIndicator
			}.onCellSelection { [weak self] (_, row) in
				guard let service = self?.service as? WalletServiceWithSend else {
					return
				}
				
				let vc = service.transferViewController()
				if let v = vc as? TransferViewControllerBase {
					v.delegate = self
				}
				
                if let split = self?.splitViewController {
                    let details = UINavigationController(rootViewController:vc)
                    split.showDetailViewController(details, sender: self)
                } else {
                    if let nav = self?.navigationController {
                        nav.pushViewController(vc, animated: true)
                    } else {
                        self?.present(vc, animated: true)
                    }
                }
                
                if let vc = self, let delegate = vc.delegate {
                    delegate.walletViewControllerSelectedRow(vc)
                }
			}
			
			section.append(sendRow)
		}
		
		form.append(section)
		
		// MARK: Notification
		if let service = service {
            // MARK: Wallet updated
			let walletUpdatedCallback = { [weak self] (notification: Notification) in
				guard let wallet = notification.userInfo?[AdamantUserInfoKey.WalletService.wallet] as? WalletAccount else {
					return
				}
                
				if let row: AlertLabelRow = self?.form.rowBy(tag: BaseRows.balance.tag) {
					let symbol = type(of: service).currencySymbol
					row.value = AdamantBalanceFormat.full.format(wallet.balance, withCurrencySymbol: symbol)
					
					if wallet.notifications > 0 {
						row.cell.alertLabel.text = String(wallet.notifications)
						
						if row.cell.alertLabel.isHidden {
							row.cell.alertLabel.isHidden = false
						}
					} else {
						row.cell.alertLabel.isHidden = true
					}
					
					row.updateCell()
				}
			}
			
			NotificationCenter.default.addObserver(forName: service.walletUpdatedNotification,
												   object: service,
												   queue: OperationQueue.main,
												   using: walletUpdatedCallback)
            
            // MARK: Wallet state updated
            let stateUpdatedCallback = { [weak self] (notification: Notification) in
                guard let newState = notification.userInfo?[AdamantUserInfoKey.WalletService.walletState] as? WalletServiceState else {
                    return
                }
                
                self?.setUiToWalletServiceState(newState)
            }
            
            NotificationCenter.default.addObserver(forName: service.serviceStateChanged,
                                                   object: service,
                                                   queue: OperationQueue.main,
                                                   using: stateUpdatedCallback)
		}
        
        if let state = service?.state {
            switch state {
            case .updating:
                setUiToWalletServiceState(.notInitiated)
                
            default:
                setUiToWalletServiceState(state)
            }
        } else {
            setUiToWalletServiceState(.notInitiated)
        }
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
	
	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
    
    
    // MARK: - To override
    
    func sendRowLocalizedLabel() -> String {
        return BaseRows.send.localized
    }
    
    func encodeForQr(address: String) -> String? {
        return nil
    }
    
    func includeLogoInQR() -> Bool {
        return false
    }
    
    
    // MARK: - Other
    
    private var currentUiState: WalletServiceState = .upToDate
    
    func setUiToWalletServiceState(_ state: WalletServiceState) {
        guard currentUiState != state else {
            return
        }
        
        switch state {
        case .updating:
            break
            
        case .upToDate:
            initiatingActivityIndicator.stopAnimating()
            tableView.isHidden = false
            errorView.isHidden = true
            
        case .notInitiated:
            initiatingActivityIndicator.startAnimating()
            tableView.isHidden = true
            errorView.isHidden = true
            
        case .initiationFailed(let reason):
            initiatingActivityIndicator.stopAnimating()
            tableView.isHidden = true
            errorView.isHidden = false
            errorLabel.text = reason
        }
        
        currentUiState = state
    }
    
    func updateWalletBalance() {
        if let row: AlertLabelRow = form.rowBy(tag: BaseRows.balance.tag), let service = self.service, let wallet = service.wallet {
            let symbol = type(of: service).currencySymbol
            let rate = currencyInfoService.getRate(for: symbol)
            let fiat = wallet.balance.doubleValue * rate
            
            DispatchQueue.main.async { [weak self] in
                row.cell.detailTextLabel?.text = AdamantBalanceFormat.full.format(wallet.balance, withCurrencySymbol: symbol) + " (" + AdamantBalanceFormat.short.format(fiat, withCurrencySymbol: self?.currencyInfoService.currentCurrency.symbol) + ")"
            }
        }
    }
}


// MARK: - TransferViewControllerDelegate
extension WalletViewControllerBase: TransferViewControllerDelegate {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?) {
        if let split = splitViewController {
            if let nav = split.viewControllers.last as? UINavigationController {
                DispatchQueue.main.async { [weak self] in
                    if let detailsViewController = detailsViewController {
                        var viewControllers = nav.viewControllers
                        viewControllers.removeLast()
                        
                        if let service = self?.service as? WalletServiceWithTransfers {
                            viewControllers.append(service.transferListViewController())
                        }
                        
                        viewControllers.append(detailsViewController)
                        nav.setViewControllers(viewControllers, animated: true)
                    } else {
                        nav.popViewController(animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    split.showDetailViewController(viewController, sender: nil)
                }
            }
        } else if let nav = navigationController {
            DispatchQueue.main.async {
                if let detailsViewController = detailsViewController {
                    var viewControllers = nav.viewControllers
                    viewControllers.removeLast()
                    viewControllers.append(detailsViewController)
                    nav.setViewControllers(viewControllers, animated: true)
                } else {
                    nav.popViewController(animated: true)
                }
            }
        } else if presentedViewController == viewController {
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(animated: true, completion: nil)
                
                if let detailsViewController = detailsViewController {
                    self?.present(detailsViewController, animated: true, completion: nil)
                }
            }
        }
    }
}
