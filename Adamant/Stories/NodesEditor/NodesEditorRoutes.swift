//
//  NodesEditorRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension AdamantScene {
    struct NodesEditor {
        static let nodesList = AdamantScene(identifier: "NodesListViewController", factory: { r in
            let c = NodesListViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.securedStore = r.resolve(SecuredStore.self)
            c.apiService = r.resolve(ApiService.self)
            c.router = r.resolve(Router.self)
            c.nodesSource = r.resolve(NodesSource.self)
            return c
        })
        
        static let nodeEditor = AdamantScene(identifier: "", factory: { r in
            let c = NodeEditorViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.apiService = r.resolve(ApiService.self)
            return c
        })
        
        private init() {}
    }
}

