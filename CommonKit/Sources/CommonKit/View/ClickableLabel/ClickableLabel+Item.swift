//
//  ClickableLabel+Item.swift
//  
//
//  Created by Andrey Golubenko on 06.08.2023.
//

import Foundation

public extension ClickableLabel {
    enum Item {
        case link(URL)
        case date(Date)
        case phoneNumber(String)
    }
    
    enum ItemType {
        case link
        case date
        case phoneNumber
    }
}

public extension NSTextCheckingResult {
    var clickableLabelItems: [ClickableLabel.Item] {
        resultType.reduce(.init()) { result, type in
            switch type {
            case .date:
                guard let value = date else { break }
                result.append(.date(value))
            case .link:
                guard let value = url else { break }
                result.append(.link(value))
            case .phoneNumber:
                guard let value = phoneNumber else { break }
                result.append(.phoneNumber(value))
            default:
                break
            }
        }
    }
}

public extension ClickableLabel.ItemType {
    var textCheckingResultType: NSTextCheckingResult.CheckingType {
        switch self {
        case .link:
            return .link
        case .date:
            return .date
        case .phoneNumber:
            return .phoneNumber
        }
    }
}

public extension ClickableLabel.Item {
    var type: ClickableLabel.ItemType {
        switch self {
        case .link:
            return .link
        case .date:
            return .date
        case .phoneNumber:
            return .phoneNumber
        }
    }
}

public extension Sequence where Element == ClickableLabel.ItemType {
    var textCheckingResultType: NSTextCheckingResult.CheckingType {
        var result = NSTextCheckingResult.CheckingType()
        forEach { result.insert($0.textCheckingResultType) }
        return result
    }
}
