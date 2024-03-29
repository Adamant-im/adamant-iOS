//
//  AdmWalletService+Send.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension AdmWalletService: WalletServiceSimpleSend {
    /// Transaction ID
    typealias T = Int
    
    func sendMoney(
        recipient: String,
        amount: Decimal,
        comments: String,
        replyToMessageId: String?
    ) async throws -> AdamantTransactionDetails {
        do {
            let transaction = try await transfersProvider.transferFunds(
                toAddress: recipient,
                amount: amount,
                comment: comments,
                replyToMessageId: replyToMessageId
            )
            
            return transaction
        } catch let error as TransfersProviderError {
            throw error.asWalletServiceError()
        } catch {
            throw WalletServiceError.remoteServiceError(
                message: error.localizedDescription,
                error: error
            )
        }
    }
}

extension TransfersProviderError {
    func asWalletServiceError() -> WalletServiceError {
        switch self {
        case .notLogged:
            return .notLogged
        case .serverError:
            return .remoteServiceError(message: self.message)
        case .accountNotFound:
            return .accountNotFound
        case .transactionNotFound:
            return .internalError(message: self.message, error: nil)
        case .networkError:
            return .networkError
        case .dependencyError:
            return .internalError(message: self.message, error: nil)
        case .internalError(let message, let error):
            return .internalError(message: message, error: error)
        case .notEnoughMoney:
            return .notEnoughMoney
        case .requestCancelled:
            return .requestCancelled
        }
    }
}
