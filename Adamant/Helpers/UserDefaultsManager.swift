//
//  UserDefaultsManager.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 22.03.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit

struct UserDefaultsManager {
    @UserDefaultsStorage(.needToShowNoActiveNodesAlert) static var needToShowNoActiveNodesAlert: Bool?
    
    static func setInitialUserDefaults() {
        needToShowNoActiveNodesAlert = true
    }
}
