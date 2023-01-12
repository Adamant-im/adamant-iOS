//
//  ComplexTransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 19.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Parchment
import SnapKit

protocol ComplexTransferViewControllerDelegate: AnyObject {
    func complexTransferViewController(_ viewController: ComplexTransferViewController, didFinishWithTransfer: TransactionDetails?, detailsViewController: UIViewController?)
}

class ComplexTransferViewController: UIViewController {
    // MARK: - Dependencies
    
    var accountService: AccountService!
    var visibleWalletsService: VisibleWalletsService!
    
    // MARK: - Properties
    var pagingViewController: PagingViewController!
    
    weak var transferDelegate: ComplexTransferViewControllerDelegate?
    var services: [WalletServiceWithSend] = []
    var partner: CoreDataAccount? {
        didSet {
            if let partner = partner {
                navigationItem.title = partner.name ?? partner.address
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let partner = partner {
            navigationItem.title = partner.name?.checkAndReplaceSystemWallets() ?? partner.address
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        // MARK: Services
        setupServices()
        
        // MARK: PagingViewController
        pagingViewController = PagingViewController()
        pagingViewController.register(UINib(nibName: "WalletCollectionViewCell", bundle: nil), for: WalletPagingItem.self)
        pagingViewController.menuItemSize = .fixed(width: 110, height: 110)
        pagingViewController.indicatorColor = UIColor.adamant.primary
        pagingViewController.indicatorOptions = .visible(height: 2, zIndex: Int.max, spacing: UIEdgeInsets.zero, insets: UIEdgeInsets.zero)
        
        pagingViewController.dataSource = self
        pagingViewController.select(index: 0)
        
        pagingViewController.borderColor = UIColor.clear
        
        view.addSubview(pagingViewController.view)
        pagingViewController.view.snp.makeConstraints {
            $0.directionalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        addChild(pagingViewController)
        
        setColors()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Other
    
    private func setupServices() {
        services.removeAll()
        let availableServices: [WalletServiceWithSend] = visibleWalletsService.sorted(includeInvisible: false)
        services = availableServices
    }
    
    func setColors() {
        view.backgroundColor = UIColor.adamant.backgroundColor
        pagingViewController.backgroundColor = UIColor.adamant.backgroundColor
        pagingViewController.menuBackgroundColor = UIColor.adamant.backgroundColor
    }
    
    @objc func cancel() {
        transferDelegate?.complexTransferViewController(self, didFinishWithTransfer: nil, detailsViewController: nil)
    }
}

extension ComplexTransferViewController: PagingViewControllerDataSource {
    func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        return services.count
    }
    
    func pagingViewController(_ pagingViewController: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        let service = services[index]
        
        let vc = service.transferViewController()
        if let v = vc as? TransferViewControllerBase {
            if let address = partner?.address {
                var name: String?
                if let title = partner?.chatroom?.title {
                    name = title
                } else if let partnerName = partner?.name {
                    name = partnerName
                }
                name = name?.checkAndReplaceSystemWallets()

                v.admReportRecipient = address
                v.recipientIsReadonly = true
                v.commentsEnabled = service.commentsEnabledForRichMessages
                v.showProgressView(animated: false)
                
                services[index].getWalletAddress(byAdamantAddress: address) { result in
                    switch result {
                    case .success(let walletAddress):
                        DispatchQueue.main.async {
                            v.recipientAddress = walletAddress
                            v.recipientName = name
                            v.hideProgress(animated: true)
                            if ERC20Token.supportedTokens.contains(where: { token in
                                return token.symbol == self.services[index].tokenSymbol
                            }) {
                                let ethWallet = self.accountService.wallets.first { wallet in
                                    return wallet.tokenSymbol == "ETH"
                                }
                                v.rootCoinBalance = ethWallet?.wallet?.balance
                            }
                        }
                    case .failure(let error):
                        v.showAlertView(title: nil, message: error.message, animated: true)
                    }
				}
			}
			
			v.delegate = self
		}
		
		return vc
	}
	
    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
		let service = services[index]
		
		guard let wallet = service.wallet else {
			return WalletPagingItem(index: index, currencySymbol: "", currencyImage: #imageLiteral(resourceName: "wallet_adm"))
		}
        
        var network = ""
        if ERC20Token.supportedTokens.contains(where: { token in
            return token.symbol == service.tokenSymbol
        }) {
            network = service.tokenNetworkSymbol
        }
		
		let item = WalletPagingItem(index: index, currencySymbol: service.tokenSymbol, currencyImage: service.tokenLogo, currencyNetwork: network)
		item.balance = wallet.balance
		
		return item
	}
}

extension ComplexTransferViewController: TransferViewControllerDelegate {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?) {
        transferDelegate?.complexTransferViewController(self, didFinishWithTransfer: transfer, detailsViewController: detailsViewController)
    }
}
