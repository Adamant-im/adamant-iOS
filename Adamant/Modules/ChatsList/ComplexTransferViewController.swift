//
//  ComplexTransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 19.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
@preconcurrency import Parchment
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
    private let walletServiceCompose: PublicWalletServiceCompose
    private let nodesStorage: NodesStorageProtocol
    
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
        walletServiceCompose: PublicWalletServiceCompose,
        nodesStorage: NodesStorageProtocol
    ) {
        self.visibleWalletsService = visibleWalletsService
        self.addressBookService = addressBookService
        self.screensFactory = screensFactory
        self.walletServiceCompose = walletServiceCompose
        self.nodesStorage = nodesStorage
        
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
        pagingViewController.register(UINib(nibName: "WalletCollectionViewCell", bundle: nil), for: WalletItemModel.self)
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
    nonisolated func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        MainActor.assertIsolated()
        
        return DispatchQueue.onMainThreadSyncSafe {
            services.count
        }
    }
    
    nonisolated func pagingViewController(
        _ pagingViewController: PagingViewController,
        viewControllerAt index: Int
    ) -> UIViewController {
        MainActor.assertIsolated()
        
        return DispatchQueue.onMainThreadSyncSafe {
            let service = services[index]
            let admService = services.first { $0.core.nodeGroups.contains(.adm) }
            let vc = screensFactory.makeTransferVC(service: service)
            
            vc.delegate = self
            
            guard let address = partner?.address else { return vc }
            
            let name = partner?.chatroom?.getName(addressBookService: addressBookService)
            
            vc.replyToMessageId = replyToMessageId
            vc.admReportRecipient = address
            vc.recipientIsReadonly = true
            vc.commentsEnabled = service.core.commentsEnabledForRichMessages && partner?.isDummy != true
            vc.showProgressView(animated: false)
            
            Task {
                guard service.core.hasEnabledNode else {
                    vc.showAlertView(
                        message: ApiServiceError.noEndpointsAvailable(
                            nodeGroupName: service.core.tokenName
                        ).errorDescription ?? .adamant.sharedErrors.unknownError,
                        animated: true
                    )
                    return
                }
                
                guard admService?.core.hasEnabledNode ?? false else {
                    vc.showAlertView(
                        message: .adamant.sharedErrors.admNodeErrorMessage(service.core.tokenSymbol),
                        animated: true
                    )
                    return
                }
                
                do {
                    let walletAddress = try await service.core
                        .getWalletAddress(
                            byAdamantAddress:
                                address
                        )
                    vc.recipientAddress = walletAddress
                    vc.recipientName = name
                    vc.hideProgress(animated: true)
                    
                    if ERC20Token.supportedTokens.contains(
                        where: { token in
                            return token.symbol == service.core.tokenSymbol
                        }
                    ) {
                        let ethWallet = walletServiceCompose.getWallet(
                            by: EthWalletService.richMessageType
                        )?.core
                        
                        vc.rootCoinBalance = ethWallet?.wallet?.balance
                    }
                } catch let error as WalletServiceError {
                    vc.showAlertView(
                        message: error.message,
                        animated: true
                    )
                } catch {
                    vc.showAlertView(
                        message: String.adamant.sharedErrors.unknownError,
                        animated: true
                    )
                }
            }
            
            return vc
        }
	}
	
    nonisolated func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        MainActor.assertIsolated()
        
        return DispatchQueue.onMainThreadSyncSafe {
            let service = services[index].core
            
            guard let wallet = service.wallet else {
                return WalletItemModel(model: .default)
            }
            
            var network: String?
            if ERC20Token.supportedTokens.contains(where: { token in
                return token.symbol == service.tokenSymbol
            }) {
                network = type(of: service).tokenNetworkSymbol
            }
            
            let item = WalletItem(
                index: index,
                currencySymbol: service.tokenSymbol,
                currencyImage: service.tokenLogo,
                isBalanceInitialized: wallet.isBalanceInitialized,
                currencyNetwork: network ?? type(of: service).tokenNetworkSymbol,
                balance: wallet.balance
            )
            
            return WalletItemModel(model: item)
        }
	}
}

extension ComplexTransferViewController: TransferViewControllerDelegate {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?) {
        transferDelegate?.complexTransferViewController(self, didFinishWithTransfer: transfer, detailsViewController: detailsViewController)
    }
}
