//
//  AdamantWalletFactoryCompose.swift
//  Adamant
//
//  Created by Andrew G on 11.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

struct AdamantWalletFactoryCompose: WalletFactoryCompose {
    private let factories: [any WalletFactory]
    
    init(
        lskWalletFactory: LskWalletFactory,
        dogeWalletFactory: DogeWalletFactory,
        dashWalletFactory: DashWalletFactory,
        btcWalletFactory: BtcWalletFactory,
        ethWalletFactory: EthWalletFactory,
        erc20WalletFactory: ERC20WalletFactory,
        admWalletFactory: AdmWalletFactory
    ) {
        factories = [
            lskWalletFactory,
            dogeWalletFactory,
            dashWalletFactory,
            btcWalletFactory,
            ethWalletFactory,
            erc20WalletFactory,
            admWalletFactory
        ]
    }
    
    func makeWalletVC(service: WalletCoreProtocol, screensFactory: ScreensFactory) -> WalletViewController {
        for factory in factories {
            guard let result = tryMakeWalletVC(
                factory: factory,
                service: service,
                screensFactory: screensFactory
            ) else { continue }
            
            return result
        }
        
        fatalError("No suitable factory")
    }
    
    func makeTransferListVC(service: WalletCoreProtocol, screenFactory: ScreensFactory) -> UIViewController {
        for factory in factories {
            guard let result = tryMakeTransferListVC(
                factory: factory,
                service: service,
                screenFactory: screenFactory
            ) else { continue }
            
            return result
        }
        
        fatalError("No suitable factory")
    }
    
    func makeTransferVC(service: WalletCoreProtocol, screenFactory: ScreensFactory) -> TransferViewControllerBase {
        for factory in factories {
            guard let result = tryMakeTransferVC(
                factory: factory,
                service: service,
                screenFactory: screenFactory
            ) else { continue }
            
            return result
        }
        
        fatalError("No suitable factory")
    }
    
    func makeDetailsVC(service: WalletCoreProtocol) -> TransactionDetailsViewControllerBase {
        for factory in factories {
            guard let result = tryMakeDetailsVC(
                factory: factory,
                service: service
            ) else { continue }
            
            return result
        }
        
        fatalError("No suitable factory")
    }
    
    func makeDetailsVC(service: WalletCoreProtocol, transaction: RichMessageTransaction) -> UIViewController? {
        for factory in factories {
            guard let result = tryMakeDetailsVC(
                factory: factory,
                service: service,
                transaction: transaction
            ) else { continue }
            
            return result
        }
        
        fatalError("No suitable factory")
    }
}

private extension AdamantWalletFactoryCompose {
    func tryMakeWalletVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletCoreProtocol,
        screensFactory: ScreensFactory
    ) -> WalletViewController? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeWalletVC(service: $0, screensFactory: screensFactory)
        }
    }
    
    func tryMakeTransferListVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletCoreProtocol,
        screenFactory: ScreensFactory
    ) -> UIViewController? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeTransferListVC(service: $0, screensFactory: screenFactory)
        }
    }
    
    func tryMakeTransferVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletCoreProtocol,
        screenFactory: ScreensFactory
    ) -> TransferViewControllerBase? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeTransferVC(service: $0, screensFactory: screenFactory)
        }
    }
    
    func tryMakeDetailsVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletCoreProtocol,
        transaction: RichMessageTransaction
    ) -> UIViewController?? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeDetailsVC(service: $0, transaction: transaction)
        }
    }
    
    func tryMakeDetailsVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletCoreProtocol
    ) -> TransactionDetailsViewControllerBase? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeDetailsVC(service: $0)
        }
    }
    
    func tryExecuteFactoryMethod<Factory: WalletFactory, Result>(
        factory _: Factory,
        service: WalletCoreProtocol,
        method: (Factory.Service) -> Result
    ) -> Result? {
        (service as? Factory.Service).map { method($0) }
    }
}
