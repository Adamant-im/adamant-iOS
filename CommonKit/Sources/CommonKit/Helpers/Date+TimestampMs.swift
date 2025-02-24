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
        let formatter = DateFormatter()
        formatter.dateFormat = "SSS"
        guard let milliseconds = Int64(formatter.string(from: self as Date)) else {
            return Int64(timeIntervalSince1970) * 1000
        }
        return Int64(timeIntervalSince1970) * 1000 + milliseconds
    }
}
