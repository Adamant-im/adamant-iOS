//
//  WalletFactoryCompose.swift
//  Adamant
//
//  Created by Andrew G on 10.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

@MainActor
protocol WalletFactoryCompose {
    func makeWalletVC(service: WalletCoreProtocol, screensFactory: ScreensFactory) -> WalletViewController
    func makeTransferListVC(service: WalletCoreProtocol, screenFactory: ScreensFactory) -> UIViewController
    func makeTransferVC(service: WalletCoreProtocol, screenFactory: ScreensFactory) -> TransferViewControllerBase
    func makeDetailsVC(service: WalletCoreProtocol) -> TransactionDetailsViewControllerBase
    
    func makeDetailsVC(
        service: WalletCoreProtocol,
        transaction: RichMessageTransaction
    ) -> UIViewController?
}
