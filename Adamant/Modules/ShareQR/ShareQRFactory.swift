//
//  ShareQRFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 17.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import UIKit

@MainActor
struct ShareQRFactory {
    let assembler: Assembler
    
    func makeViewController() -> ShareQrViewController {
        ShareQrViewController(dialogService: assembler.resolve(DialogService.self)!)
    }
}
