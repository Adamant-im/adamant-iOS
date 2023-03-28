//
//  ERC20WalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import web3swift
import struct BigInt.BigUInt

extension ERC20WalletService: RichMessageProviderWithStatusCheck {
    func statusInfoFor(transaction: RichMessageTransaction) async -> TransactionStatusInfo {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash] else {
            return .init(sentDate: nil, status: .inconsistent)
        }
        
        guard let erc20Transaction = try? await getTransaction(by: hash) else {
            return .init(sentDate: nil, status: .pending)
        }
        
        return .init(
            sentDate: erc20Transaction.date,
            status: getStatus(
                erc20Transaction: erc20Transaction,
                transaction: transaction
            )
        )
    }
}

private extension ERC20WalletService {
    func getStatus(
        erc20Transaction: EthTransaction,
        transaction: RichMessageTransaction
    ) -> TransactionStatus {
        let status = erc20Transaction.receiptStatus.asTransactionStatus()
        guard status == .success else { return status }
        
        // MARK: Check addresses
        if transaction.isOutgoing {
            guard
                let id = ethWallet?.address,
                erc20Transaction.senderAddress == id
            else {
                return .inconsistent
            }
        } else {
            guard
                let id = ethWallet?.address,
                erc20Transaction.to == id
            else {
                return .inconsistent
            }
        }
        
        // MARK: Compare amounts
        guard
            let raw = transaction.richContent?[RichContentKeys.transfer.amount],
            let reportedValue = AdamantBalanceFormat.deserializeBalance(from: raw)
        else {
            return .inconsistent
        }
        
        let min = reportedValue - reportedValue*0.005
        let max = reportedValue + reportedValue*0.005
        
        guard (min...max).contains(erc20Transaction.value ?? 0) else {
            return .inconsistent
        }
        
        return .success
    }
}
