//
//  AdamantResources+CoreData.swift
//  Adamant
//
//  Created by Andrey Golubenko on 22.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation

extension AdamantResources {
    static let coreDataModel = Bundle.main.url(
        forResource: "Adamant",
        withExtension: "momd"
    )!
}
