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
    
    func makeWalletVC(service: WalletService, screensFactory: ScreensFactory) -> WalletViewController {
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
    
    func makeTransferListVC(service: WalletService, screenFactory: ScreensFactory) -> UIViewController {
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
    
    func makeTransferVC(service: WalletService, screenFactory: ScreensFactory) -> TransferViewControllerBase {
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
    
    func makeDetailsVC(service: WalletService) -> TransactionDetailsViewControllerBase {
        for factory in factories {
            guard let result = tryMakeDetailsVC(
                factory: factory,
                service: service
            ) else { continue }
            
            return result
        }
        
        fatalError("No suitable factory")
    }
    
    func makeDetailsVC(service: WalletService, transaction: RichMessageTransaction) -> UIViewController? {
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
        service: WalletService,
        screensFactory: ScreensFactory
    ) -> WalletViewController? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeWalletVC(service: $0, screensFactory: screensFactory)
        }
    }
    
    func tryMakeTransferListVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletService,
        screenFactory: ScreensFactory
    ) -> UIViewController? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeTransferListVC(service: $0, screensFactory: screenFactory)
        }
    }
    
    func tryMakeTransferVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletService,
        screenFactory: ScreensFactory
    ) -> TransferViewControllerBase? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeTransferVC(service: $0, screensFactory: screenFactory)
        }
    }
    
    func tryMakeDetailsVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletService,
        transaction: RichMessageTransaction
    ) -> UIViewController?? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeDetailsVC(service: $0, transaction: transaction)
        }
    }
    
    func tryMakeDetailsVC<Factory: WalletFactory>(
        factory: Factory,
        service: WalletService
    ) -> TransactionDetailsViewControllerBase? {
        tryExecuteFactoryMethod(factory: factory, service: service) {
            factory.makeDetailsVC(service: $0)
        }
    }
    
    func tryExecuteFactoryMethod<Factory: WalletFactory, Result>(
        factory: Factory,
        service: WalletService,
        method: (Factory.Service) -> Result
    ) -> Result? {
        guard factory.typeSymbol == type(of: service.core).richMessageType else {
            return nil
        }
        return (service as? Factory.Service).map { method($0) }
    }
}
