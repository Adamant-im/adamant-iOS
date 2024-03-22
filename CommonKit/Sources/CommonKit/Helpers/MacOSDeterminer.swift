//
//  MacOSDeterminer.swift
//
//
//  Created by Stanislav Jelezoglo on 14.03.2024.
//

import Foundation

public var isMacOS: Bool = {
    #if targetEnvironment(macCatalyst)
    true
    #else
    ProcessInfo.processInfo.isiOSAppOnMac
    #endif
}()
