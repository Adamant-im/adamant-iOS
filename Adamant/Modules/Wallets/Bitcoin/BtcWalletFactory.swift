//
//  BtcWalletFactory.swift
//  Adamant
//
//  Created by Andrew G on 09.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject
import UIKit
import CommonKit

struct BtcWalletFactory: WalletFactory {
    typealias Service = BtcWalletService
    
    let assembler: Assembler
    
    func makeWalletVC(service: Service, screensFactory: ScreensFactory) -> WalletViewController {
        let c = BtcWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
        c.dialogService = assembler.resolve(DialogService.self)
        c.currencyInfoService = assembler.resolve(CurrencyInfoService.self)
        c.accountService = assembler.resolve(AccountService.self)
        c.screensFactory = screensFactory
        c.service = service
        return c
    }
    
    func makeTransferListVC(service: Service, screensFactory: ScreensFactory) -> UIViewController {
        let c = BtcTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
        c.dialogService = assembler.resolve(DialogService.self)
        c.btcWalletService = service
        c.addressBook = assembler.resolve(AddressBookService.self)
        c.screensFactory = screensFactory
        return c
    }
    
    func makeTransferVC(service: Service, screensFactory: ScreensFactory) -> TransferViewControllerBase {
        let vc = BtcTransferViewController(
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
        guard let hash = transaction.getRichValue(for: RichContentKeys.transfer.hash)
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
            transaction: nil,
            richTransaction: transaction,
            service: service
        )
    }
    
    func makeDetailsVC(service: Service) -> TransactionDetailsViewControllerBase {
        makeTransactionDetailsVC(service: service)
    }
}

private extension BtcWalletFactory {
    func makeTransactionDetailsVC(
        hash: String,
        senderId: String?,
        recipientId: String?,
        senderAddress: String,
        recipientAddress: String,
        comment: String?,
        transaction: BtcTransaction?,
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
        vc.transaction = transaction ?? failedTransaction
        vc.richTransaction = richTransaction
        return vc
    }
    
    func makeTransactionDetailsVC(service: Service) -> BtcTransactionDetailsViewController {
        let vc = BtcTransactionDetailsViewController(
            dialogService: assembler.resolve(DialogService.self)!,
            currencyInfo: assembler.resolve(CurrencyInfoService.self)!,
            addressBookService: assembler.resolve(AddressBookService.self)!,
            accountService: assembler.resolve(AccountService.self)!
        )
        
        vc.service = service
        return vc
    }
}
