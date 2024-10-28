//
//  RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Andrey Golubenko on 26.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct TransactionStatusInfo {
    let sentDate: Date?
    let status: TransactionStatus
}

extension TransactionStatusInfo {
    init(error: Error) {
        self.init(sentDate: nil, status: .pending)
    }
}
