//
//  SharedContainer.swift
//  Adamant
//
//  Created by Andrey Golubenko on 01.08.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject

struct SharedContainer {
    let assembler = Assembler([SharedAssembly()])
    
    func resolve<T>(_ type: T.Type) -> T? {
        assembler.resolver.resolve(T.self)
    }
}
