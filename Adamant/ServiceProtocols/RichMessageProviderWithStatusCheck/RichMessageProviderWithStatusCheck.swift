//
//  RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Andrey Golubenko on 26.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct TransactionStatusInfo {
    let sentDate: Date?
    let status: TransactionStatus
}

protocol RichMessageProviderWithStatusCheck: RichMessageProvider {
    func statusInfoFor(transaction: RichMessageTransaction) async -> TransactionStatusInfo
}
