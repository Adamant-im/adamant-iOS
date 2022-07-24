//
//  MacOSDeterminer.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 08.07.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

var isMacOS: Bool = {
    #if targetEnvironment(macCatalyst)
        return true
    #else
    if #available(iOS 14.0, *) {
        return ProcessInfo.processInfo.isiOSAppOnMac
    } else {
        return false
    }
    #endif
}()
