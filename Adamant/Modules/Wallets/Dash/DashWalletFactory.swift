//
//  DashWalletFactory.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Swinject
import CommonKit
import UIKit

struct DashWalletFactory: WalletFactory {
    typealias Service = DashWalletService
    
    let assembler: Assembler
    
    func makeWalletVC(service: Service, screensFactory: ScreensFactory) -> WalletViewController {
        let c = DashWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
        c.dialogService = assembler.resolve(DialogService.self)
        c.currencyInfoService = assembler.resolve(CurrencyInfoService.self)
        c.accountService = assembler.resolve(AccountService.self)
        c.service = service
        c.screensFactory = screensFactory
        return c
    }
    
    func makeTransferListVC(service: Service, screensFactory: ScreensFactory) -> UIViewController {
        let c = DashTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
        c.dialogService = assembler.resolve(DialogService.self)
        c.screensFactory = screensFactory
        c.walletService = service
        c.dashWalletService = service
        return c
    }
    
    func makeTransferVC(service: Service, screensFactory: ScreensFactory) -> TransferViewControllerBase {
        let vc = DashTransferViewController(
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
    
    func makeDetailsVC(service: Service, transaction: RichMessageTransaction) -> UIViewController? {
        guard
            let hash = transaction.getRichValue(for: RichContentKeys.transfer.hash),
            let address = assembler.resolve(AccountService.self)?.account?.address
        else { return nil }
                
        let comment: String?
        if let raw = transaction.getRichValue(for: RichContentKeys.transfer.comments), raw.count > 0 {
            comment = raw
        } else {
            comment = nil
        }
        
        return makeTransactionDetailsVC(
            hash: hash,
            senderId: transaction.senderId,
            recipientId: transaction.recipientId,
            senderAddress: "",
            recipientAddress: "",
            comment: comment,
            address: address,
            blockId: nil,
            transaction: nil,
            richTransaction: transaction,
            service: service
        )
    }
    
    func makeDetailsVC(service: Service) -> TransactionDetailsViewControllerBase {
        makeTransactionDetailsVC(service: service)
    }
}

private extension DashWalletFactory {
    func makeTransactionDetailsVC(
        hash: String,
        senderId: String?,
        recipientId: String?,
        senderAddress: String,
        recipientAddress: String,
        comment: String?,
        address: String,
        blockId: String?,
        transaction: BTCRawTransaction?,
        richTransaction: RichMessageTransaction,
        service: Service
    ) -> UIViewController {
        let vc = makeTransactionDetailsVC(service: service)
        
        let amount: Decimal
        if let amountRaw = richTransaction.getRichValue(for: RichContentKeys.transfer.amount),
           let decimal = Decimal(string: amountRaw) {
            amount = decimal
        } else {
            amount = 0
        }
        
        var dashTransaction = transaction?.asBtcTransaction(DashTransaction.self, for: address)
        if let blockId = blockId {
            dashTransaction = transaction?.asBtcTransaction(DashTransaction.self, for: address, blockId: blockId)
        }
        let failedTransaction = SimpleTransactionDetails(
            txId: hash,
            senderAddress: senderAddress,
            recipientAddress: recipientAddress,
            dateValue: nil,
            amountValue: amount,
            feeValue: nil,
            confirmationsValue: nil,
            blockValue: nil,
            isOutgoing: richTransaction.isOutgoing,
            transactionStatus: nil
        )
        
        vc.senderId = senderId
        vc.recipientId = recipientId
        vc.comment = comment
        vc.transaction = dashTransaction ?? failedTransaction
        vc.richTransaction = richTransaction
        return vc
    }
    
    func makeTransactionDetailsVC(service: Service) -> DashTransactionDetailsViewController {
        let vc = DashTransactionDetailsViewController(
            dialogService: assembler.resolve(DialogService.self)!,
            currencyInfo: assembler.resolve(CurrencyInfoService.self)!,
            addressBookService: assembler.resolve(AddressBookService.self)!,
            accountService: assembler.resolve(AccountService.self)!,
            walletService: service
        )
        
        vc.service = service
        return vc
    }
}
