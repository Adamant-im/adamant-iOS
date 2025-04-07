//
//  UserDefaultsManager.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 22.03.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit

struct UserDefaultsManager {
    @UserDefaultsStorage(.needsToShowNoActiveNodesAlert) static var needsToShowNoActiveNodesAlert: Bool?

    static func setInitialUserDefaults() {
        needsToShowNoActiveNodesAlert = true
    }
}
