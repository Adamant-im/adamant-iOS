//
//  ReadedHeightService.swift
//  Adamant
//
//  Created by Аркадий Торвальдс on 30.09.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct ReadedHeight: Codable {
    let timeStamp: Double
    var unreadTransactions: [String]
}

actor ReadedHeightService {
    
    private var chatsReadHeight: [String: ReadedHeight] {
        get {
            guard let data = UserDefaults.standard.data(forKey: StoreKey.chatProvider.readedHeights),
                  let rv = try? JSONDecoder().decode([String: ReadedHeight].self, from: data) else {
                return [:]
            }
            return rv
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: StoreKey.chatProvider.readedHeights)
            }
        }
    }
    
}

extension ReadedHeightService: ReadedHeightServiceProtocol {
    func getLastReadedTimeStamp(adress: String) -> Double? {
        return chatsReadHeight[adress]?.timeStamp
    }
    
    func setFirstReadedTimeStamp(adress: String, transactions: Set<ChatTransaction>) {
        let trs = transactions.compactMap { $0.dateValue }
        
        guard let maxReadedDate = trs.max() else { return }
        let maxReadedTimeStamp = maxReadedDate.timeIntervalSince1970
        
        var readedHeight = ReadedHeight(timeStamp: maxReadedTimeStamp, unreadTransactions: [])
        
        for tr in transactions where tr.dateValue == maxReadedDate {
            readedHeight.unreadTransactions.append(tr.txId)
        }
        
        print("AAAA set timeStamp \(adress) \(readedHeight.timeStamp)")
        chatsReadHeight[adress] = readedHeight
    }
}
