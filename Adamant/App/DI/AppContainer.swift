//
//  AppContainer.swift
//  Adamant
//
//  Created by Andrew G on 09.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject

struct AppContainer {
    let assembler = Assembler([AppAssembly()])

    func resolve<T>(_ type: T.Type) -> T? {
        assembler.resolve(T.self)
    }
}
