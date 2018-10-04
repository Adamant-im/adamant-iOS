//
//  TransferTransaction+TransactionDetails.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension TransferTransaction {//: TransactionDetails {
    var id: String {
        return self.transactionId ?? ""
    }
    
    var senderAddress: String {
        return self.senderId ?? ""
    }
    
    var recipientAddress: String {
        return self.recipientId ?? ""
    }
    
    var amountValue: Double {
        return self.amount?.doubleValue ?? 0
    }
    
    var feeValue: Double {
        return self.fee?.doubleValue ?? 0
    }
    
    var confirmationsValue: String {
        return "\(self.confirmations)"
    }
    
    var block: String {
        return self.blockId ?? ""
    }
    
    //    var explorerUrl: URL? {
    //        return URL(string: "https://explorer.adamant.im/tx/\(id)")
    //    }
}
