//
//  MacOSDeterminer.swift
//
//
//  Created by Stanislav Jelezoglo on 14.03.2024.
//

import Foundation

public let isMacOS: Bool = {
    #if targetEnvironment(macCatalyst)
    true
    #else
    ProcessInfo.processInfo.isiOSAppOnMac
    #endif
}()
