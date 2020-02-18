//
//  ComplexTransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 19.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Parchment

protocol ComplexTransferViewControllerDelegate: class {
    func complexTransferViewController(_ viewController: ComplexTransferViewController, didFinishWithTransfer: TransactionDetails?, detailsViewController: UIViewController?)
}

class ComplexTransferViewController: UIViewController {
    // MARK: - Dependencies
    
    var accountService: AccountService!
    
    
    // MARK: - Properties
    var pagingViewController: PagingViewController<WalletPagingItem>!
    
    weak var transferDelegate: ComplexTransferViewControllerDelegate?
    var services: [WalletServiceWithSend]!
    var partner: CoreDataAccount? {
        didSet {
            if let partner = partner {
                navigationItem.title = partner.name ?? partner.address
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        if let partner = partner {
            navigationItem.title = partner.name ?? partner.address
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        // MARK: Services
        services = accountService.wallets.compactMap { $0 as? WalletServiceWithSend }
        
        for service in services {
            NotificationCenter.default.addObserver(forName: service.walletUpdatedNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
                self?.pagingViewController.reloadData()
            }
        }
        
        // MARK: PagingViewController
        pagingViewController = PagingViewController<WalletPagingItem>()
        pagingViewController.menuItemSource = .nib(nib: UINib(nibName: "WalletCollectionViewCell", bundle: nil))
        pagingViewController.menuItemSize = .fixed(width: 110, height: 110)
        pagingViewController.indicatorColor = UIColor.adamant.primary
        pagingViewController.indicatorOptions = .visible(height: 2, zIndex: Int.max, spacing: UIEdgeInsets.zero, insets: UIEdgeInsets.zero)
        
        pagingViewController.dataSource = self
        pagingViewController.select(index: 0)
        
        pagingViewController.borderColor = UIColor.clear
        
        view.addSubview(pagingViewController.view)
        view.constrainToEdges(pagingViewController.view, relativeToSafeArea: true)
        addChild(pagingViewController)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    func cancel() {
        transferDelegate?.complexTransferViewController(self, didFinishWithTransfer: nil, detailsViewController: nil)
    }
}

extension ComplexTransferViewController: PagingViewControllerDataSource {
    func numberOfViewControllers<T>(in pagingViewController: PagingViewController<T>) -> Int {
        if let services = services {
            return services.count
        } else {
            return 0
        }
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
        let service = services[index]
        
        let vc = service.transferViewController()
        if let v = vc as? TransferViewControllerBase {
            if let address = partner?.address {
                let name = partner?.name
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
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
        let service = accountService.wallets[index]
        
        guard let wallet = service.wallet else {
            return WalletPagingItem(index: index, currencySymbol: "", currencyImage: #imageLiteral(resourceName: "wallet_adm")) as! T
        }
        
        let serviceType = type(of: service)
        
        let item = WalletPagingItem(index: index, currencySymbol: serviceType.currencySymbol, currencyImage: serviceType.currencyLogo)
        item.balance = wallet.balance
        
        return item as! T
    }
}

extension ComplexTransferViewController: TransferViewControllerDelegate {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?) {
        transferDelegate?.complexTransferViewController(self, didFinishWithTransfer: transfer, detailsViewController: detailsViewController)
    }
}
