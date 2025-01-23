//
//  AdamantScreensFactory.swift
//  Adamant
//
//  Created by Andrew G on 10.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import Swinject
import SwiftUI

@MainActor
struct AdamantScreensFactory: ScreensFactory {

    private let walletFactoryCompose: WalletFactoryCompose
    private let admWalletFactory: AdmWalletFactory
    private let chatListFactory: ChatListFactory
    private let chatFactory: ChatFactory
    private let nodesEditorFactory: NodesEditorFactory
    private let delegatesFactory: DelegatesFactory
    private let settingsFactory: SettingsFactory
    private let contributeFactory: ContributeFactory
    private let loginFactory: LoginFactory
    private let onboardFactory: OnboardFactory
    private let shareQRFactory: ShareQRFactory
    private let accountFactory: AccountFactory
    private let vibrationSelectionFactory: VibrationSelectionFactory
    private let partnerQRFactory: PartnerQRFactory
    private let coinsNodesListFactory: CoinsNodesListFactory
    private let chatSelectTextFactory: ChatSelectTextViewFactory
    private let notificationsFactory: NotificationsFactory
    private let notificationSoundsFactory: NotificationSoundsFactory
    private let storageUsageFactory: StorageUsageFactory
    private let pkGeneratorFactory: PKGeneratorFactory
        
    init(assembler: Assembler) {
        admWalletFactory = .init(assembler: assembler)
        chatListFactory = .init(assembler: assembler)
        chatFactory = .init(assembler: assembler)
        nodesEditorFactory = .init(assembler: assembler)
        delegatesFactory = .init(assembler: assembler)
        settingsFactory = .init(assembler: assembler)
        contributeFactory = .init(parent: assembler)
        loginFactory = .init(assembler: assembler)
        onboardFactory = .init()
        shareQRFactory = .init(assembler: assembler)
        accountFactory = .init(assembler: assembler)
        vibrationSelectionFactory = .init(parent: assembler)
        partnerQRFactory = .init(parent: assembler)
        coinsNodesListFactory = .init(parent: assembler)
        chatSelectTextFactory = .init()
        notificationsFactory = .init(parent: assembler)
        notificationSoundsFactory = .init(parent: assembler)
        storageUsageFactory = .init(parent: assembler)
        pkGeneratorFactory = .init(parent: assembler)
        
        walletFactoryCompose = AdamantWalletFactoryCompose(
            klyWalletFactory: .init(assembler: assembler),
            dogeWalletFactory: .init(assembler: assembler),
            dashWalletFactory: .init(assembler: assembler),
            btcWalletFactory: .init(assembler: assembler),
            ethWalletFactory: .init(assembler: assembler),
            erc20WalletFactory: .init(assembler: assembler),
            admWalletFactory: admWalletFactory
        )
    }
    
    func makeWalletVC(service: WalletService) -> WalletViewController {
        walletFactoryCompose.makeWalletVC(service: service, screensFactory: self)
    }
    
    func makeTransferListVC(service: WalletService) -> UIViewController {
        walletFactoryCompose.makeTransferListVC(service: service, screenFactory: self)
    }
    
    func makeTransferVC(service: WalletService) -> TransferViewControllerBase {
        walletFactoryCompose.makeTransferVC(service: service, screenFactory: self)
    }
    
    func makeDetailsVC(service: WalletService) -> TransactionDetailsViewControllerBase {
        walletFactoryCompose.makeDetailsVC(service: service)
    }
    
    func makeDetailsVC(service: WalletService, transaction: RichMessageTransaction) -> UIViewController? {
        walletFactoryCompose.makeDetailsVC(service: service, transaction: transaction)
    }
    
    func makeAdmTransactionDetails(transaction: TransferTransaction) -> UIViewController {
        admWalletFactory.makeDetailsVC(transaction: transaction, screensFactory: self)
    }
    
    func makeAdmTransactionDetails() -> AdmTransactionDetailsViewController {
        admWalletFactory.makeDetailsVC(screensFactory: self)
    }
    
    func makeBuyAndSell() -> UIViewController {
        admWalletFactory.makeBuyAndSellVC(screenFactory: self)
    }
    
    func makeChatList() -> UIViewController {
        chatListFactory.makeChatListVC(screensFactory: self)
    }
    
    func makeChat() -> ChatViewController {
        chatFactory.makeViewController(screensFactory: self)
    }
    
    func makeNewChat() -> NewChatViewController {
        chatListFactory.makeNewChatVC(screensFactory: self)
    }
    
    func makeDelegatesList() -> UIViewController {
        delegatesFactory.makeDelegatesListVC(screensFactory: self)
    }
    
    func makeDelegateDetails() -> DelegateDetailsViewController {
        delegatesFactory.makeDelegateDetails()
    }
    
    func makeNodesList() -> UIViewController {
        nodesEditorFactory.makeNodesListVC(screensFactory: self)
    }
    
    func makeNodeEditor() -> NodeEditorViewController {
        nodesEditorFactory.makeNodeEditorVC()
    }
    
    func makeEula() -> UIViewController {
        onboardFactory.makeEulaVC()
    }
    
    func makeOnboard() -> UIViewController {
        onboardFactory.makeOnboardVC()
    }
    
    func makeShareQr() -> ShareQrViewController {
        shareQRFactory.makeViewController()
    }
    
    func makeAccount() -> UIViewController {
        accountFactory.makeViewController(screensFactory: self)
    }
    
    func makeComplexTransfer() -> UIViewController {
        chatListFactory.makeComplexTransferVC(screensFactory: self)
    }
    
    func makeSearchResults() -> SearchResultsViewController {
        chatListFactory.makeSearchResultsViewController(screensFactory: self)
    }
    
    func makeSecurity() -> UIViewController {
        settingsFactory.makeSecurityVC(screensFactory: self)
    }
    
    func makeQRGenerator() -> UIViewController {
        settingsFactory.makeQRGeneratorVC()
    }
    
    func makePKGenerator() -> UIViewController {
        pkGeneratorFactory.makeViewController()
    }
    
    func makeAbout() -> UIViewController {
        settingsFactory.makeAboutVC(screensFactory: self)
    }
    
    func makeNotifications() -> UIViewController {
        notificationsFactory.makeViewController(screensFactory: self)
    }
    
    func makeNotificationSounds(target: NotificationTarget) -> NotificationSoundsView {
        notificationSoundsFactory.makeView(target: target)
    }
    
    func makeVisibleWallets() -> UIViewController {
        settingsFactory.makeVisibleWalletsVC()
    }
    
    func makeContribute() -> UIViewController {
        contributeFactory.makeViewController()
    }
    
    func makeStorageUsage() -> UIViewController {
        storageUsageFactory.makeViewController()
    }
    
    func makeLogin() -> LoginViewController {
        loginFactory.makeViewController(screenFactory: self)
    }
    
    func makeVibrationSelection() -> UIViewController {
        vibrationSelectionFactory.makeViewController()
    }
    
    func makePartnerQR(partner: CoreDataAccount) -> UIViewController {
        partnerQRFactory.makeViewController(partner: partner, screenFactory: self)
    }
    
    func makeCoinsNodesList(context: CoinsNodesListContext) -> UIViewController {
        coinsNodesListFactory.makeViewController(context: context)
    }
    
    func makeChatSelectTextView(text: String) -> UIViewController {
        chatSelectTextFactory.makeViewController(text: text)
    }
}
