//
//  NodeAvailabilityService.swift
//  Adamant
//
//  Created by Yana Silosieva on 07.11.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit

@MainActor
protocol NodeAvailabilityProtocol {
    func checkNodeAvailability(
        in walletCore: WalletCoreProtocol,
        vc: UIViewController
    ) -> Bool
    
    func checkNodeAvailability(
        in nodeGroup: NodeGroup,
        vc: UIViewController
    ) -> Bool
}

@MainActor
final class NodeAvailabilityService: NodeAvailabilityProtocol {
    
    // MARK: Dependencies
    
    private let dialogService: DialogService
    private let apiServiceCompose: ApiServiceComposeProtocol
    private let screensFactory: ScreensFactory
    
    init(
        dialogService: DialogService,
        apiServiceCompose: ApiServiceComposeProtocol,
        screensFactory: ScreensFactory
    ) {
        self.dialogService = dialogService
        self.apiServiceCompose = apiServiceCompose
        self.screensFactory = screensFactory
    }
    
    func checkNodeAvailability(
        in nodeGroup: NodeGroup,
        vc: UIViewController
    ) -> Bool {
        guard apiServiceCompose.get(nodeGroup)?.hasEnabledNode == true
        else {
            dialogService.showNoActiveNodesAlert(
                nodeName: NodeGroup.adm.name
            ) { [weak self] in
                guard let self = self else { return }
                
                self.presentNodeListVC(
                    screensFactory: self.screensFactory,
                    node: nodeGroup,
                    rootVC: vc
                )
            }
            
            return false
        }
        
        guard apiServiceCompose.get(nodeGroup)?.hasActiveNode == true
        else {
            dialogService.showError(
                withMessage: noActiveNodesError(for: nodeGroup.name),
                supportEmail: false,
                error: nil
            )
            return false
        }
        
        return true
    }
    
    func checkNodeAvailability(
        in walletCore: WalletCoreProtocol,
        vc: UIViewController
    ) -> Bool {
        guard walletCore.hasEnabledNode else {
            let network = type(of: walletCore).tokenNetworkSymbol
            dialogService.showNoActiveNodesAlert(
                nodeName: network
            ) { [weak self] in
                guard let self = self,
                      let nodeGroup = walletCore.nodeGroups.first else { return }
                
                self.presentNodeListVC(
                    screensFactory: self.screensFactory,
                    node: nodeGroup,
                    rootVC: vc
                )
            }
            return false
        }
        
        return true
    }
}

private extension NodeAvailabilityService {
    func presentNodeListVC(
        screensFactory: ScreensFactory,
        node: NodeGroup,
        rootVC: UIViewController
    ) {
        let vc = node == .adm
        ? screensFactory.makeNodesList()
        : screensFactory.makeCoinsNodesList(context: .menu)
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        rootVC.present(nav, animated: true, completion: nil)
    }
}

private func noActiveNodesError(for nodeGroupName: String) -> String {
    .localizedStringWithFormat(
        .localized(
            "ApiService.InternalError.NoActiveNodesAvailable",
            comment: "Serious internal error: No active nodes available"
        ),
        nodeGroupName
    ).localized
}
