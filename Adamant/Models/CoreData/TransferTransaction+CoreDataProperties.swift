//
//  TransferTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

extension TransferTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransferTransaction> {
        return NSFetchRequest<TransferTransaction>(entityName: "TransferTransaction")
    }

    @NSManaged public var comment: String?
    @NSManaged public var replyToId: String?
    @NSManaged public var decodedReplyMessage: String?
    @NSManaged public var reactionsData: Data?
    @NSManaged public var richMessageTransactions: Set<RichMessageTransaction>?
    
    var reactions: Set<Reaction>? {
        get {
            guard let data = reactionsData else {
                return nil
            }

            return try? PropertyListDecoder().decode(Set<Reaction>.self, from: data)
        }
        
        set {
            guard let value = newValue else {
                reactionsData = nil
                return
            }

            let data = try? PropertyListEncoder().encode(value)
            reactionsData = data
        }
    }
}

extension TransferTransaction: AdamantTransactionDetails {
    var partnerName: String? {
        partner?.name
    }
    
    var showToChat: Bool? {
        guard let partner = partner as? CoreDataAccount,
              let chatroom = partner.chatroom,
              !chatroom.isReadonly
        else {
            return false
        }
        
        return true
    }
    
    var chatRoom: Chatroom? {
        let partner = partner as? CoreDataAccount
        return partner?.chatroom
    }
    func addToRichMessageTransactions(_ transaction: RichMessageTransaction) {
        self.mutableSetValue(forKey: "richMessageTransactions").add(transaction)
    }
}
