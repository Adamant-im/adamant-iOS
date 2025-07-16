//
//  NewMessageSeparatorState.swift
//  Adamant
//
//  Created by Владимир Клевцов on 23. 4. 2025..
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit

struct NewMessageSeparatorState {
    @ObservableValue var separatorIndex: Int?
    var separatorId: String?
    var isFirstUpdate: Bool = true
    var didAddSeparator: Bool = false
    var isScrollPositionNearlyTheBottom = true
    var isEnterFromRemoteNotifivation: Bool = false
    
    var shouldUpdateSeparator: Bool {
        isFirstUpdate
        || !isScrollPositionNearlyTheBottom
        || isEnterFromRemoteNotifivation
    }
}
