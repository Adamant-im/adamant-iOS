//
//  RichTransactionReplyService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol RichTransactionReplyService: Actor, AnyObject {
    func startObserving()
}
