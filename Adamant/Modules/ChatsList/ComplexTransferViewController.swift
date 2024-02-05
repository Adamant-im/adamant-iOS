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
import CommonKit

@MainActor
protocol ComplexTransferViewControllerDelegate: AnyObject {
    func complexTransferViewController(_ viewController: ComplexTransferViewController, didFinishWithTransfer: TransactionDetails?, detailsViewController: UIViewController?)
}

final class ComplexTransferViewController: UIViewController {
    // MARK: - Dependencies
    
    private let visibleWalletsService: VisibleWalletsService
    private let addressBookService: AddressBookService
    private let screensFactory: ScreensFactory
    private let walletServiceCompose: WalletServiceCompose
    
    // MARK: - Properties
    var pagingViewController: PagingViewController!
    
    weak var transferDelegate: ComplexTransferViewControllerDelegate?
    var services: [WalletService] = []
    var partner: CoreDataAccount? {
        didSet {
            navigationItem.title = partner?.chatroom?.getName(addressBookService: addressBookService)
        }
    }
    var replyToMessageId: String?
    
    // MARK: Init
    
    init(
        visibleWalletsService: VisibleWalletsService,
        addressBookService: AddressBookService,
        screensFactory: ScreensFactory,
        walletServiceCompose: WalletServiceCompose
    ) {
        self.visibleWalletsService = visibleWalletsService
        self.addressBookService = addressBookService
        self.screensFactory = screensFactory
        self.walletServiceCompose = walletServiceCompose
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        let availableServices: [WalletService] = visibleWalletsService.sorted(includeInvisible: false)
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
        
        let vc = screensFactory.makeTransferVC(service: service)
        
        guard let v = vc as? TransferViewControllerBase else { return vc }
        
        v.delegate = self
        
        guard let address = partner?.address else { return vc }
        
        let name = partner?.chatroom?.getName(addressBookService: addressBookService)
        
        v.replyToMessageId = replyToMessageId
        v.admReportRecipient = address
        v.recipientIsReadonly = true
        v.commentsEnabled = service.core.commentsEnabledForRichMessages && partner?.isDummy != true
        v.showProgressView(animated: false)
        
        Task {
            do {
                let walletAddress = try await service.core
                    .getWalletAddress(
                        byAdamantAddress:
                            address
                    )
                v.recipientAddress = walletAddress
                v.recipientName = name
                v.hideProgress(animated: true)
                
                if ERC20Token.supportedTokens.contains(
                    where: { token in
                        return token.symbol == service.core.tokenSymbol
                    }
                ) {
                    let ethWallet = walletServiceCompose.getWallet(
                        by: EthWalletService.richMessageType
                    )?.core
                    
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
                    message: String.adamant.sharedErrors.unknownError,
                    animated: true
                )
            }
        }
		
		return vc
	}
	
    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        let service = services[index].core
		
		guard let wallet = service.wallet else {
            return WalletPagingItem(
                index: index,
                currencySymbol: "",
                currencyImage: .asset(named: "adamant_wallet") ?? .init(),
                isBalanceInitialized: false)
		}
        
        var network = ""
        if ERC20Token.supportedTokens.contains(where: { token in
            return token.symbol == service.tokenSymbol
        }) {
            network = type(of: service).tokenNetworkSymbol
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
