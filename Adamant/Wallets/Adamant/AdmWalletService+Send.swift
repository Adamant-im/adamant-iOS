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
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Adamant.transfer) as? AdmTransferViewController else {
            fatalError("Can't get AdmTransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    func sendMoney(
        recipient: String,
        amount: Decimal,
        comments: String,
        replyToMessageId: String?
    ) async throws -> TransactionDetails {
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
            throw WalletServiceError.internalError(
                message: String.adamant.sharedErrors.unknownError,
                error: nil
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
