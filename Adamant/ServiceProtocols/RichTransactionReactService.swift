//
//  RichTransactionReactService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol RichTransactionReactService: Actor, AnyObject {
    func startObserving()
}
