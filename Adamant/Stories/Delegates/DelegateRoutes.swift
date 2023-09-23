//
//  DelegateRoutes.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension AdamantScene {
    struct Delegates {
        static let delegates = AdamantScene(identifier: "DelegatesListViewController", factory: { r in
            DelegatesListViewController(
                apiService: r.resolve(ApiService.self)!,
                accountService: r.resolve(AccountService.self)!,
                dialogService: r.resolve(DialogService.self)!,
                router: r.resolve(Router.self)!
            )
        })
        
        static let delegateDetails = AdamantScene(identifier: "DelegateDetailsViewController", factory: { r in
            let c = DelegateDetailsViewController(nibName: "DelegateDetailsViewController", bundle: nil)
            c.apiService = r.resolve(ApiService.self)
            c.accountService = r.resolve(AccountService.self)
            c.dialogService = r.resolve(DialogService.self)
            return c
        })
        
        private init() {}
    }
}
