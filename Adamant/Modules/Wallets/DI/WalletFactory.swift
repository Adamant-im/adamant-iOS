//
//  WalletFactory.swift
//  Adamant
//
//  Created by Andrew G on 11.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

@MainActor
protocol WalletFactory {
    associatedtype Service = WalletService
    
    func makeWalletVC(service: Service, screensFactory: ScreensFactory) -> WalletViewController
    func makeTransferListVC(service: Service, screensFactory: ScreensFactory) -> UIViewController
    func makeTransferVC(service: Service, screensFactory: ScreensFactory) -> TransferViewControllerBase
    func makeDetailsVC(service: Service) -> TransactionDetailsViewControllerBase
    func makeDetailsVC(service: Service, transaction: RichMessageTransaction) -> UIViewController?
}
