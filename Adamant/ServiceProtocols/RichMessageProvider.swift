//
//  RichMessageProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit

protocol RichMessageProvider: AnyObject {
    /// Lowercased!!
    static var richMessageType: String { get }
    
    // MARK: Transactions fetch info
    
    static var newPendingInterval: Int { get }
    static var oldPendingInterval: Int { get }
    static var registeredInterval: Int { get }
    static var newPendingAttempts: Int { get }
    static var oldPendingAttempts: Int { get }
    static var txConsistencyMaxTime: Int { get }
    
    var dynamicRichMessageType: String { get }
    
    var tokenSymbol: String { get }
    var tokenLogo: UIImage { get }
    
    // MARK: Events
    func richMessageTapped(for transaction: RichMessageTransaction, in chat: ChatViewController)
    
    // MARK: Chats list
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString
}

protocol RichMessageProviderWithStatusCheck: RichMessageProvider {
    func statusFor(transaction: RichMessageTransaction) async throws -> TransactionStatus
    
    var delayBetweenChecks: TimeInterval { get }
}

extension RichMessageProviderWithStatusCheck {
    var delayBetweenChecks: TimeInterval {
        return 30.0
    }
}
