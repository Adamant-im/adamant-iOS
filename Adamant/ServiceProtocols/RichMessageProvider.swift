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

protocol RichMessageProvider: WalletService {
    /// Lowercased!!
    static var richMessageType: String { get }
    
    // MARK: Transactions fetch info
    
    var newPendingInterval: TimeInterval { get }
    var oldPendingInterval: TimeInterval { get }
    var registeredInterval: TimeInterval { get }
    var newPendingAttempts: Int { get }
    var oldPendingAttempts: Int { get }
    var consistencyMaxTime: Double { get }
    
    var dynamicRichMessageType: String { get }
    
    var tokenSymbol: String { get }
    var tokenLogo: UIImage { get }
    
    // MARK: Chats list
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString
}
