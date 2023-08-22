//
//  BtcWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 20/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension BtcWalletService: RichMessageProviderWithStatusCheck {
    func statusInfoFor(transaction: RichMessageTransaction) async -> TransactionStatusInfo {
        guard let hash = transaction.getRichValue(for: RichContentKeys.transfer.hash)
        else {
            return .init(sentDate: nil, status: .inconsistent)
        }
        
        do {
            let btcTransaction = try await getTransaction(by: hash)
            
            return .init(
                sentDate: btcTransaction.dateValue,
                status: getStatus(transaction: transaction, btcTransaction: btcTransaction)
            )
        } catch {
            switch error {
            case ApiServiceError.networkError(_):
                return .init(sentDate: nil, status: .noNetwork)
            default:
                return .init(sentDate: nil, status: .pending)
            }
        }
    }
}

private extension BtcWalletService {
    func getStatus(
        transaction: RichMessageTransaction,
        btcTransaction: BtcTransaction
    ) -> TransactionStatus {
        guard let status = btcTransaction.transactionStatus else {
            return .inconsistent
        }
        
        guard status == .success else {
            return status
        }
        
        // MARK: Check address
        guard
            transaction.isOutgoing && btcTransaction.senderAddress == btcWallet?.address
                || btcTransaction.recipientAddress == btcWallet?.address
        else { return .inconsistent }
        
        // MARK: Check amount
        if let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount),
           let reported = AdamantBalanceFormat.deserializeBalance(from: raw) {
            guard reported == btcTransaction.amountValue else {
                return .inconsistent
            }
        }
        
        return .success
    }
}
