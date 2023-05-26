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

@MainActor
protocol ComplexTransferViewControllerDelegate: AnyObject {
    func complexTransferViewController(_ viewController: ComplexTransferViewController, didFinishWithTransfer: TransactionDetails?, detailsViewController: UIViewController?)
}

class ComplexTransferViewController: UIViewController {
    // MARK: - Dependencies
    
    var accountService: AccountService!
    var visibleWalletsService: VisibleWalletsService!
    var addressBookService: AddressBookService!
    
    // MARK: - Properties
    var pagingViewController: PagingViewController!
    
    weak var transferDelegate: ComplexTransferViewControllerDelegate?
    var services: [WalletServiceWithSend] = []
    var partner: CoreDataAccount? {
        didSet {
            navigationItem.title = partner?.chatroom?.getName(addressBookService: addressBookService)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        // MARK: Services
        setupServices()
        
        // MARK: PagingViewController
        pagingViewController = PagingViewController()
        pagingViewController.register(UINib(nibName: "WalletCollectionViewCell", bundle: nil), for: WalletPagingItem.self)
        pagingViewController.menuItemSize = .fixed(width: 110, height: 114)
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
    
    @MainActor
    func pagingViewController(_ pagingViewController: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        let service = services[index]
        
        let vc = service.transferViewController()
        
        guard let v = vc as? TransferViewControllerBase else { return vc }
        
        v.delegate = self
        
        guard let address = partner?.address else { return vc }
        
        let name = partner?.chatroom?.getName(addressBookService: addressBookService)
        
        v.admReportRecipient = address
        v.recipientIsReadonly = true
        v.commentsEnabled = service.commentsEnabledForRichMessages && partner?.isDummy != true
        v.showProgressView(animated: false)
        
        Task {
            do {
                let walletAddress = try await services[index]
                    .getWalletAddress(
                        byAdamantAddress:
                            address
                    )
                v.recipientAddress = walletAddress
                v.recipientName = name
                v.hideProgress(animated: true)
                
                if ERC20Token.supportedTokens.contains(
                    where: { token in
                        return token.symbol == self.services[index].tokenSymbol
                    }
                ) {
                    let ethWallet = self.accountService.wallets.first { wallet in
                        return wallet.tokenSymbol == "ETH"
                    }
                    v.rootCoinBalance = ethWallet?.wallet?.balance
                }
            } catch let error as WalletServiceError {
                v.showAlertView(
                    title: nil,
                    message: error.message,
                    animated: true
                )
            } catch {
                v.showAlertView(
                    title: nil,
                    message: String.adamantLocalized.sharedErrors.unknownError,
                    animated: true
                )
            }
        }
		
		return vc
	}
	
    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
		let service = services[index]
		
		guard let wallet = service.wallet else {
            return WalletPagingItem(
                index: index,
                currencySymbol: "",
                currencyImage: #imageLiteral(resourceName: "adamant_wallet"),
                isBalanceInitialized: false)
		}
        
        var network = ""
        if ERC20Token.supportedTokens.contains(where: { token in
            return token.symbol == service.tokenSymbol
        }) {
            network = service.tokenNetworkSymbol
        }
		
		let item = WalletPagingItem(
            index: index,
            currencySymbol: service.tokenSymbol,
            currencyImage: service.tokenLogo,
            isBalanceInitialized: wallet.isBalanceInitialized,
            currencyNetwork: network)
        
		item.balance = wallet.balance
		
		return item
	}
}

extension ComplexTransferViewController: TransferViewControllerDelegate {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?) {
        transferDelegate?.complexTransferViewController(self, didFinishWithTransfer: transfer, detailsViewController: detailsViewController)
    }
}
