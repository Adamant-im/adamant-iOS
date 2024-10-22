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

@MainActor
struct NodesEditorFactory {
    let assembler: Assembler
    
    func makeNodesListVC(screensFactory: ScreensFactory) -> UIViewController {
        NodesListViewController(
            dialogService: assembler.resolve(DialogService.self)!,
            securedStore: assembler.resolve(SecuredStore.self)!,
            screensFactory: screensFactory,
            nodesStorage: assembler.resolve(NodesStorageProtocol.self)!,
            nodesAdditionalParamsStorage: assembler.resolve(NodesAdditionalParamsStorageProtocol.self)!,
            apiService: assembler.resolve(AdamantApiServiceProtocol.self)!,
            socketService: assembler.resolve(SocketService.self)!
        )
    }
    
    func makeNodeEditorVC() -> NodeEditorViewController {
        let c = NodeEditorViewController()
        c.dialogService = assembler.resolve(DialogService.self)
        c.apiService = assembler.resolve(AdamantApiServiceProtocol.self)
        c.nodesStorage = assembler.resolve(NodesStorageProtocol.self)
        return c
    }
}
