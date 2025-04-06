//
//  TimeInterval+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

extension TimeInterval {
    public init(milliseconds: Int) {
        self.init(Double(milliseconds) / 1000)
    }
}
