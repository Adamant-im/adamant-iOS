//
//  LskWalletFactory.swift
//  Adamant
//
//  Created by Anton Boyarkin on 27/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import UIKit
import CommonKit
import LiskKit

struct LskWalletFactory: WalletFactory {
    typealias Service = WalletService
    
    let typeSymbol: String = LskWalletService.richMessageType
    let assembler: Assembler
    
    func makeWalletVC(service: Service, screensFactory: ScreensFactory) -> WalletViewController {
        LskWalletViewController(
            dialogService: assembler.resolve(DialogService.self)!,
            currencyInfoService: assembler.resolve(CurrencyInfoService.self)!,
            accountService: assembler.resolve(AccountService.self)!,
            screensFactory: screensFactory,
            walletServiceCompose: assembler.resolve(WalletServiceCompose.self)!,
            service: service
        )
    }
    
    func makeTransferListVC(service: Service, screensFactory: ScreensFactory) -> UIViewController {
        LskTransactionsViewController(
            walletService: service,
            dialogService: assembler.resolve(DialogService.self)!,
            reachabilityMonitor: assembler.resolve(ReachabilityMonitor.self)!,
            screensFactory: screensFactory
        )
    }
    
    func makeTransferVC(service: Service, screensFactory: ScreensFactory) -> TransferViewControllerBase {
        LskTransferViewController(
            chatsProvider: assembler.resolve(ChatsProvider.self)!,
            accountService: assembler.resolve(AccountService.self)!,
            accountsProvider: assembler.resolve(AccountsProvider.self)!,
            dialogService: assembler.resolve(DialogService.self)!,
            screensFactory: screensFactory,
            currencyInfoService: assembler.resolve(CurrencyInfoService.self)!,
            increaseFeeService: assembler.resolve(IncreaseFeeService.self)!,
            vibroService: assembler.resolve(VibroService.self)!,
            walletService: service,
            reachabilityMonitor: assembler.resolve(ReachabilityMonitor.self)!,
            nodesStorage: assembler.resolve(NodesStorageProtocol.self)!
        )
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
            comment: comment,
            senderAddress: "",
            recipientAddress: "",
            transaction: nil,
            richTransaction: transaction,
            service: service
        )
    }
    
    func makeDetailsVC(service: Service) -> TransactionDetailsViewControllerBase {
        makeTransactionDetailsVC(service: service)
    }
}

private extension LskWalletFactory {
    private func makeTransactionDetailsVC(
        hash: String,
        senderId: String?,
        recipientId: String?,
        comment: String?,
        senderAddress: String,
        recipientAddress: String,
        transaction: Transactions.TransactionModel?,
        richTransaction: RichMessageTransaction,
        service: Service
    ) -> UIViewController {
        let vc = makeTransactionDetailsVC(service: service)
        vc.senderId = senderId
        vc.recipientId = recipientId
        vc.comment = comment
        
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
            transactionStatus: nil, 
            nonceRaw: nil
        )

        vc.transaction = transaction ?? failedTransaction
        vc.richTransaction = richTransaction
        return vc
    }
    
    func makeTransactionDetailsVC(service: Service) -> LskTransactionDetailsViewController {
        LskTransactionDetailsViewController(
            dialogService: assembler.resolve(DialogService.self)!,
            currencyInfo: assembler.resolve(CurrencyInfoService.self)!,
            addressBookService: assembler.resolve(AddressBookService.self)!,
            accountService:  assembler.resolve(AccountService.self)!,
            walletService: service,
            languageService: assembler.resolve(LanguageStorageProtocol.self)!
        )
    }
}
