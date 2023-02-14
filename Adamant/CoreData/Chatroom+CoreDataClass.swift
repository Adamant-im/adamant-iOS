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
    
    func markAsReaded() {
        hasUnreadMessages = false
       
        if let trs = transactions as? Set<ChatTransaction> {
            trs.filter { $0.isUnread }.forEach { $0.isUnread = false }
        }
        lastTransaction?.isUnread = false
    }
    
    func getFirstUnread() -> ChatTransaction? {
        if let trs = transactions as? Set<ChatTransaction> {
            return trs.filter { $0.isUnread }.map { $0 }.first
        }
        return nil
    }
    
    private var semaphore: DispatchSemaphore?
    
    func updateLastTransaction() {
        var semaphore = self.semaphore
        
        if let semaphore = semaphore {
            semaphore.wait()
        } else {
            semaphore = DispatchSemaphore(value: 1)
        }
        
        self.semaphore = semaphore
        defer {
            self.semaphore = nil
            semaphore?.signal()
        }
        
        if let transactions = transactions?.filtered(using: NSPredicate(format: "isHidden == false")) as? Set<ChatTransaction> {
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
                    
                /// Rare case of identical date, compare IDs
                case .orderedSame:
                    guard let lid = lhs.transactionId else {
                        return true
                    }
                    
                    guard let hid = rhs.transactionId else {
                        return false
                    }
                    
                    return lid < hid
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
    
    @MainActor
    func updateLastTransaction() async {
        if let transactions = transactions?.filtered(using: NSPredicate(format: "isHidden == false")) as? Set<ChatTransaction> {
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
                    
                /// Rare case of identical date, compare IDs
                case .orderedSame:
                    guard let lid = lhs.transactionId else {
                        return true
                    }
                    
                    guard let hid = rhs.transactionId else {
                        return false
                    }
                    
                    return lid < hid
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
