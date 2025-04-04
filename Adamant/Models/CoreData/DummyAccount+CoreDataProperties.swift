//
//  DummyAccount+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//
//

import CoreData
import Foundation

extension DummyAccount {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DummyAccount> {
        return NSFetchRequest<DummyAccount>(entityName: "DummyAccount")
    }

}
