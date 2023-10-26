//
//  Assembler+Extension.swift
//  Adamant
//
//  Created by Andrew G on 09.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject

extension Assembler {
    func resolve<T>(_ type: T.Type) -> T? {
        resolver.resolve(T.self)
    }
}
