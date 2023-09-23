//
//  LskWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import LiskKit
import CommonKit

extension LskWalletService: RichMessageProviderWithStatusCheck {
    func statusInfoFor(transaction: RichMessageTransaction) async -> TransactionStatusInfo {
        guard let hash = transaction.getRichValue(for: RichContentKeys.transfer.hash)
        else {
            return .init(sentDate: nil, status: .inconsistent)
        }
        
        var lskTransaction: Transactions.TransactionModel
        
        do {
            lskTransaction = try await getTransaction(by: hash)
        } catch {
            switch error {
            case ApiServiceError.networkError(_):
                return .init(sentDate: nil, status: .noNetwork)
            default:
                return .init(sentDate: nil, status: .pending)
            }
        }
        
        lskTransaction.updateConfirmations(value: lastHeight)
        
        return .init(
            sentDate: lskTransaction.sentDate,
            status: getStatus(
                lskTransaction: lskTransaction,
                transaction: transaction
            )
        )
    }
}

private extension LskWalletService {
    func getStatus(
        lskTransaction: Transactions.TransactionModel,
        transaction: RichMessageTransaction
    ) -> TransactionStatus {
        guard lskTransaction.blockId != nil else { return .registered }
        
        guard let status = lskTransaction.transactionStatus else {
            return .inconsistent
        }
        
        guard status == .success else {
            return status
        }
        
        // MARK: Check address
        if transaction.isOutgoing {
            guard lskTransaction.senderAddress == lskWallet?.address else {
                return .inconsistent
            }
        } else {
            guard lskTransaction.recipientAddress == lskWallet?.address else {
                return .inconsistent
            }
        }
        
        // MARK: Check amount
        if let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount),
           let reported = AdamantBalanceFormat.deserializeBalance(from: raw) {
            let min = reported - reported*0.005
            let max = reported + reported*0.005
            
            guard (min...max).contains(lskTransaction.amountValue ?? 0) else {
                return .inconsistent
            }
        }
        
        return .success
    }
}
