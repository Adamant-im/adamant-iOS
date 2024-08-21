//
//  DelegatesFactory.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject
import CommonKit

struct DelegatesFactory {
    let assembler: Assembler
    
    func makeDelegatesListVC(screensFactory: ScreensFactory) -> UIViewController {
        DelegatesListViewController(
            apiService: assembler.resolve(ApiService.self)!,
            accountService: assembler.resolve(AccountService.self)!,
            dialogService: assembler.resolve(DialogService.self)!,
            screensFactory: screensFactory
        )
    }
    
    func makeDelegateDetails() -> DelegateDetailsViewController {
        let c = DelegateDetailsViewController(nibName: "DelegateDetailsViewController", bundle: nil)
        c.apiService = assembler.resolve(ApiService.self)
        c.accountService = assembler.resolve(AccountService.self)
        c.dialogService = assembler.resolve(DialogService.self)
        return c
    }
}
