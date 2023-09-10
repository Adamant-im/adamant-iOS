//
//  ScreensFactory.swift
//  Adamant
//
//  Created by Andrew G on 10.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

@MainActor
protocol ScreensFactory {
    // MARK: Wallets
    
    func makeWalletVC(service: WalletService) -> WalletViewController
    func makeTransferListVC(service: WalletService) -> UIViewController
    func makeTransferVC(service: WalletService) -> TransferViewControllerBase
    func makeDetailsVC(service: WalletService) -> TransactionDetailsViewControllerBase
    
    func makeDetailsVC(
        service: WalletService,
        transaction: RichMessageTransaction
    ) -> UIViewController?
    
    func makeAdmTransactionDetails(transaction: TransferTransaction) -> UIViewController
    func makeAdmTransactionDetails() -> AdmTransactionDetailsViewController
    func makeBuyAndSell() -> UIViewController
    
    // MARK: Chats
    
    func makeChat() -> ChatViewController
    func makeChatList() -> UIViewController
    func makeNewChat() -> NewChatViewController
    func makeComplexTransfer() -> UIViewController
    func makeSearchResults() -> SearchResultsViewController
    
    // MARK: Delegates
    
    func makeDelegatesList() -> UIViewController
    func makeDelegateDetails() -> DelegateDetailsViewController
    
    // MARK: Nodes
    
    func makeNodesList() -> UIViewController
    func makeNodeEditor() -> NodeEditorViewController
    
    // MARK: Other
    
    func makeEula() -> UIViewController
    func makeOnboard() -> UIViewController
    func makeShareQr() -> ShareQrViewController
    func makeAccount() -> UIViewController
    func makeSecurity() -> UIViewController
    func makeQRGenerator() -> UIViewController
    func makePKGenerator() -> UIViewController
    func makeAbout() -> UIViewController
    func makeNotifications() -> UIViewController
    func makeVisibleWallets() -> UIViewController
    func makeContribute() -> UIViewController
    func makeLogin() -> LoginViewController
}
