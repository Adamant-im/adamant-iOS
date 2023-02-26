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
    true
    #else
    ProcessInfo.processInfo.isiOSAppOnMac
    #endif
}()
