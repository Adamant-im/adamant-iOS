//
//  TransactionStatus.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum TransactionStatus: Int16 {
    case notInitiated
    case updating
    case pending
    case success
    case failed
    
    var localized: String {
        switch self {
        case .notInitiated, .updating:
            return "Обновление..."
        case .pending:
            return "Ожидается подтверждение"
        case .success:
            return "Успешно"
        case .failed:
            return "Ошибка"
        }
    }
}
