//
//  Chatroom+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Chatroom)
public class Chatroom: NSManagedObject {
    static let entityName = "Chatroom"
    
    func markMessageAsRead(id: String) {
        guard let trs = transactions as? Set<ChatTransaction> else { return }

        var unreadCount = 0
        trs.forEach { tr in
            if tr.txId == id {
                tr.isUnread = false
            }
            unreadCount += tr.isUnread ? 1 : 0
        }

        hasUnreadMessages = unreadCount != 0
    }
    
    func markAsReaded() {
        hasUnreadMessages = false
       
        if let trs = transactions as? Set<ChatTransaction> {
            trs.filter { $0.isUnread }.forEach { $0.isUnread = false }
        }
        lastTransaction?.isUnread = false
    }
    
    func getUnreadCount() -> Int {
        (transactions as? Set<ChatTransaction>)?.filter { $0.isUnread }.count ?? .zero
    }
    
    func getFirstUnread() -> ChatTransaction? {
        if let trs = transactions as? Set<ChatTransaction> {
            return trs.filter { $0.isUnread }.map { $0 }.first
        }
        return nil
    }
    
    @MainActor func getName(addressBookService: AddressBookService) -> String? {
        guard let partner = partner else { return nil }
        let result: String?
        if let address = partner.address,
           let name = addressBookService.getName(for: address) {
            result = name
        } else if let title = title {
            result = title
        } else if let name = partner.name {
            result = name
        } else {
            result = partner.address
        }
        
        return result?.checkAndReplaceSystemWallets()
    }
    
    @MainActor func hasPartnerName(addressBookService: AddressBookService) -> Bool {
        guard let partner = partner else { return false }
        
        return partner.address.flatMap { addressBookService.getName(for: $0) } != nil
        || title != nil
        || partner.name != nil
    }
    
    private let semaphore = DispatchSemaphore(value: 1)
    
    func updateLastTransaction() {
        semaphore.wait()
        defer { semaphore.signal() }
        
        if let transactions = transactions?.filtered(
            using: NSPredicate(format: "isHidden == false")
        ) as? Set<ChatTransaction> {
            if let newest = transactions.sorted(by: { (lhs: ChatTransaction, rhs: ChatTransaction) in
                guard let l = lhs.date as Date? else {
                    return true
                }
                
                guard let r = rhs.date as Date? else {
                    return false
                }
                
                switch l.compare(r) {
                case .orderedAscending:
                    return true
                    
                case .orderedDescending:
                    return false
                    
                // Rare case of identical date, compare IDs
                case .orderedSame:
                    return lhs.transactionId < rhs.transactionId
                }
            }).last {
                if newest != lastTransaction {
                    lastTransaction = newest
                    updatedAt = newest.date
                }
            } else if lastTransaction != nil {
                lastTransaction = nil
                updatedAt = nil
            }
        }
    }
}
