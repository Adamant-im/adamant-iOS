//
//  AdmWalletFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 28.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import UIKit

struct AdmWalletFactory: WalletFactory {
    typealias Service = AdmWalletService
    
    let assembler: Assembler
    
    func makeWalletVC(service: AdmWalletService, screensFactory: ScreensFactory) -> WalletViewController {
        let c = AdmWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
        c.dialogService = assembler.resolve(DialogService.self)
        c.currencyInfoService = assembler.resolve(CurrencyInfoService.self)
        c.accountService = assembler.resolve(AccountService.self)
        c.service = service
        c.screensFactory = screensFactory
        return c
    }
    
    func makeTransferListVC(service: Service, screensFactory: ScreensFactory) -> UIViewController {
        AdmTransactionsViewController(
            nibName: "TransactionsListViewControllerBase",
            bundle: nil,
            accountService: assembler.resolve(AccountService.self)!,
            transfersProvider: assembler.resolve(TransfersProvider.self)!,
            chatsProvider: assembler.resolve(ChatsProvider.self)!,
            dialogService: assembler.resolve(DialogService.self)!,
            stack: assembler.resolve(CoreDataStack.self)!,
            screensFactory: screensFactory,
            addressBookService: assembler.resolve(AddressBookService.self)!,
            admService: service
        )
    }
    
    func makeTransferVC(service: Service, screensFactory: ScreensFactory) -> TransferViewControllerBase {
        let vc = AdmTransferViewController(
            chatsProvider: assembler.resolve(ChatsProvider.self)!,
            accountService: assembler.resolve(AccountService.self)!,
            accountsProvider: assembler.resolve(AccountsProvider.self)!,
            dialogService: assembler.resolve(DialogService.self)!,
            screensFactory: screensFactory,
            currencyInfoService: assembler.resolve(CurrencyInfoService.self)!,
            increaseFeeService: assembler.resolve(IncreaseFeeService.self)!,
            vibroService: assembler.resolve(VibroService.self)!
        )
        
        vc.service = service
        return vc
    }
    
    func makeDetailsVC(service: Service, transaction: RichMessageTransaction) -> UIViewController? { nil }
    
    func makeDetailsVC(service: Service) -> TransactionDetailsViewControllerBase {
        fatalError("ScreensFactory in necessary for AdmTransactionDetailsViewController")
    }
    
    func makeDetailsVC(screensFactory: ScreensFactory) -> AdmTransactionDetailsViewController {
        makeTransactionDetailsVC(screensFactory: screensFactory)
    }
    
    func makeDetailsVC(transaction: TransferTransaction, screensFactory: ScreensFactory) -> UIViewController {
        let controller = makeTransactionDetailsVC(screensFactory: screensFactory)
        controller.adamantTransaction = transaction
        controller.comment = transaction.comment
        controller.senderId = transaction.senderId
        controller.recipientId = transaction.recipientId
        return controller
    }
    
    func makeBuyAndSellVC() -> UIViewController {
        let c = BuyAndSellViewController()
        c.accountService = assembler.resolve(AccountService.self)
        c.dialogService = assembler.resolve(DialogService.self)
        return c
    }
}

private extension AdmWalletFactory {
    func makeTransactionDetailsVC(screensFactory: ScreensFactory) -> AdmTransactionDetailsViewController {
        AdmTransactionDetailsViewController(
            accountService: assembler.resolve(AccountService.self)!,
            transfersProvider: assembler.resolve(TransfersProvider.self)!,
            screensFactory: screensFactory,
            dialogService: assembler.resolve(DialogService.self)!,
            currencyInfo: assembler.resolve(CurrencyInfoService.self)!,
            addressBookService: assembler.resolve(AddressBookService.self)!,
            languageService: assembler.resolve(LanguageStorageProtocol.self)!
        )
    }
}
