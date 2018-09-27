//
//  RichMessageTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData
import MessageKit

@objc(RichMessageTransaction)
public class RichMessageTransaction: ChatTransaction {
    static let entityName = "RichMessageTransaction"
    
    override func serializedMessage() -> String? {
        if let richContent = richContent, let data = try? JSONEncoder().encode(richContent), let raw = String(data: data, encoding: String.Encoding.utf8) {
            return raw
        } else {
            return nil
        }
    }
    
    
    // Hack? Yes. So?
    public var kind: MessageKind = .text("?")
}
