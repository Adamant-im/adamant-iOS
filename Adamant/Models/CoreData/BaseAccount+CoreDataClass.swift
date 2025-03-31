//
//  BaseAccount+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//
//

import CoreData
import Foundation

@objc(BaseAccount)
public class BaseAccount: NSManagedObject, @unchecked Sendable {
    static let baseEntityName = "BaseAccount"
}
