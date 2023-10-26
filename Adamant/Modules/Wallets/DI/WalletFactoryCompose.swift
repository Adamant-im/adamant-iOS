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
    func makeWalletVC(service: WalletService, screensFactory: ScreensFactory) -> WalletViewController
    func makeTransferListVC(service: WalletService, screenFactory: ScreensFactory) -> UIViewController
    func makeTransferVC(service: WalletService, screenFactory: ScreensFactory) -> TransferViewControllerBase
    func makeDetailsVC(service: WalletService) -> TransactionDetailsViewControllerBase
    
    func makeDetailsVC(
        service: WalletService,
        transaction: RichMessageTransaction
    ) -> UIViewController?
}
