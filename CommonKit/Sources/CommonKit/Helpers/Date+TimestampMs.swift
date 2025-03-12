//
//  Date+Milliseconds.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 24.02.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation

public extension NSDate {
    var timeIntervalMillisecondsSince1970: Int64 {
        Int64(timeIntervalSince1970 * 1000)
    }
}
