//
//  DelegateRoutes.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene {
    struct Delegates {
        static let delegates = AdamantScene(identifier: "DelegatesListViewController", factory: { r in
            let c = DelegatesListViewController()
            c.apiService = r.resolve(ApiService.self)
            c.accountService = r.resolve(AccountService.self)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
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
