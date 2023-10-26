//
//  NodesEditorFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject
import CommonKit

struct NodesEditorFactory {
    let assembler: Assembler
    
    func makeNodesListVC(screensFactory: ScreensFactory) -> UIViewController {
        let c = NodesListViewController()
        c.screensFactory = screensFactory
        c.dialogService = assembler.resolve(DialogService.self)
        c.securedStore = assembler.resolve(SecuredStore.self)
        c.apiService = assembler.resolve(ApiService.self)
        c.socketService = assembler.resolve(SocketService.self)
        c.nodesSource = assembler.resolve(NodesSource.self)
        return c
    }
    
    func makeNodeEditorVC() -> NodeEditorViewController {
        let c = NodeEditorViewController()
        c.dialogService = assembler.resolve(DialogService.self)
        c.apiService = assembler.resolve(ApiService.self)
        return c
    }
}
