//
//  ServerModelResponse+Mapper.swift
//  Adamant
//
//  Created by Andrew G on 01.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

extension ServerModelResponse {
    func resolved() -> ApiServiceResult<T> {
        if let model = model {
            return .success(model)
        } else {
            return .failure(translateServerError(error))
        }
    }
}

extension ServerCollectionResponse {
    func resolved() -> ApiServiceResult<[T]> {
        if let collection = collection {
            return .success(collection)
        } else {
            return .failure(translateServerError(error))
        }
    }
}

extension TransactionIdResponse {
    func resolved() -> ApiServiceResult<UInt64> {
        if let ransactionId = transactionId {
            return .success(ransactionId)
        } else {
            return .failure(translateServerError(error))
        }
    }
}

extension GetPublicKeyResponse {
    func resolved() -> ApiServiceResult<String> {
        if let publicKey = publicKey {
            return .success(publicKey)
        } else {
            return .failure(translateServerError(error))
        }
    }
}

private func translateServerError(_ error: String?) -> ApiServiceError {
    guard let error = error else { return .internalError(error: InternalAPIError.unknownError) }
    
    switch error {
    case "Account not found":
        return .accountNotFound
    default:
        return .serverError(error: error)
    }
}
