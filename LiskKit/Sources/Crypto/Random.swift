//
//  Random.swift
//  Lisk
//
//  Created by Erica Sadun on 9/20/16.
//  https://gist.github.com/erica/aa0b1164fd82d98d73c58919d3155984
//

import Foundation
#if os(Linux)
import Glibc
#endif

internal struct Random {
    #if os(Linux)
    static var initialized = false
    #endif

    static func roll(max: Int) -> Int {
        #if os(Linux)
        if !initialized {
            srandom(UInt32(time(nil)))
            initialized = true
        }
        return Int(random() % max)
        #else
        return Int(arc4random_uniform(UInt32(max)))
        #endif
    }
}
