//
//  AdamantNotificationInAppService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import CommonKit

final class AdamantNotificationInAppService: NSObject, NotificationInAppService {
    
    // MARK: Dependencies
    
    private let chatsProvider: ChatsProvider
    private let dialogService: DialogService
    private let accountService: AccountService
    private var richMessageProviders: [String: RichMessageProvider] = [:]
    
    // MARK: Proprieties
    
    private var unreadController: NSFetchedResultsController<ChatTransaction>?
    private let defaultAvatar = UIImage.asset(named: "avatar-chat-placeholder") ?? .init()
    
    // MARK: Init
    
    init(
        chatsProvider: ChatsProvider,
        dialogService: DialogService,
        accountService: AccountService
    ) {
        self.chatsProvider = chatsProvider
        self.dialogService = dialogService
        self.accountService = accountService
        super.init()
        
        self.richMessageProviders = self.makeRichMessageProviders()
    }
    
    func makeRichMessageProviders() -> [String: RichMessageProvider] {
        .init(
            uniqueKeysWithValues: accountService
                .wallets
                .compactMap { $0 as? RichMessageProvider }
                .map { ($0.dynamicRichMessageType, $0) }
        )
    }
    
    func startObserving() {
        Task {
            unreadController = await chatsProvider.getUnreadMessagesController()
            unreadController?.delegate = self
            try? unreadController?.performFetch()
        }
    }
}

// MARK: Core Data

extension AdamantNotificationInAppService: NSFetchedResultsControllerDelegate {
     func controller(
        _: NSFetchedResultsController<NSFetchRequestResult>,
        didChange object: Any,
        at _: IndexPath?,
        for type_: NSFetchedResultsChangeType,
        newIndexPath _: IndexPath?
    ) {
        guard type_ == .insert else { return }
          
        if let transaction = object as? ChatTransaction {
            showNotification(for: transaction)
        }
        
        let forceUpdate = object is TransferTransaction
        || object is RichMessageTransaction

        guard forceUpdate else { return }
        
        NotificationCenter.default.post(
            name: .AdamantAccountService.forceUpdateBalance,
            object: nil
        )
        
        Task {
            await Task.sleep(interval: 4)
            
            NotificationCenter.default.post(
                name: .AdamantAccountService.forceUpdateBalance,
                object: nil
            )
        }
    }
}

// MARK: Working with in-app notifications

private extension AdamantNotificationInAppService {
    func showNotification(for transaction: ChatTransaction) {
        Task {
            // MARK: Do not show notifications for initial sync
            
            guard await chatsProvider.isInitiallySynced else {
                return
            }
            
            // MARK: Show notification only for incomming transactions
            
            guard !transaction.silentNotification,
                  !transaction.isOutgoing,
                  let chatroom = transaction.chatroom,
                  await shoudPresentNotification(chatroom: chatroom),
                  let partner = chatroom.partner
            else {
                return
            }
            
            // MARK: Prepare notification
            
            let title = partner.name ?? partner.address
            let text = shortDescription(for: transaction)
            
            let image: UIImage
            if let ava = partner.avatar, let img = UIImage.asset(named: ava) {
                image = img
            } else {
                image = defaultAvatar
            }
            
            // MARK: Show notification with tap handler
            await dialogService.showNotification(
                title: title?.checkAndReplaceSystemWallets(),
                message: text,
                image: image
            ) { [weak self, chatroom] in
                self?.presentChatroom(chatroom)
            }
        }
    }
    
    func shortDescription(for transaction: ChatTransaction) -> String? {
        switch transaction {
        case let message as MessageTransaction:
            guard let text = message.message else {
                return nil
            }
            
            let raw: String
            if message.isOutgoing {
                raw = "\(String.adamant.chatList.sentMessagePrefix)\(text)"
            } else {
                raw = text
            }
            
            return raw
            
        case let transfer as TransferTransaction:
            if let admService = richMessageProviders[AdmWalletService.richMessageType] as? AdmWalletService {
                return admService.shortDescription(for: transfer)
            } else {
                return nil
            }
            
        case let richMessage as RichMessageTransaction:
            if let type = richMessage.richType,
               let provider = richMessageProviders[type] {
                return provider.shortDescription(for: richMessage).string
            }
            
            if richMessage.additionalType == .reply,
               let content = richMessage.richContent,
               let text = content[RichContentKeys.reply.replyMessage] as? String {
                
                let prefix = richMessage.isOutgoing
                ? "\(String.adamant.chatList.sentMessagePrefix)"
                : ""
                
                let extraSpace = richMessage.isOutgoing ? "  " : ""
                return "\(prefix)\(extraSpace)\(text)"
            }
            
            if richMessage.additionalType == .reaction,
               let content = richMessage.richContent,
               let reaction = content[RichContentKeys.react.react_message] as? String {
                let prefix = richMessage.isOutgoing
                ? "\(String.adamant.chatList.sentMessagePrefix)"
                : ""
                
                let text = reaction.isEmpty
                ? "\(prefix)\(String.adamant.chatList.removedReaction) \(reaction)"
                : "\(prefix)\(String.adamant.chatList.reacted) \(reaction)"
                
                return text
            }
            
            if let serialized = richMessage.serializedMessage() {
                return serialized
            }
            
            return nil
        default:
            return nil
        }
    }
    
    @MainActor func shoudPresentNotification(chatroom: Chatroom) -> Bool {
        guard chatroom != presentedChatroom(),
              !chatroom.isHidden,
              !(rootViewController() is ChatListViewController)
        else { return false }
        
        return true
    }
    
    @MainActor func presentedChatroom() -> Chatroom? {
        guard let vc = rootViewController() as? ChatViewController
        else { return nil }
        
        return vc.viewModel.chatroom
    }
    
    func rootViewController() -> UIViewController? {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        guard let windowScene = scene as? UIWindowScene else {
            return nil
        }
        
        var topController = windowScene.keyWindow?.rootViewController
        
        while (topController?.presentedViewController != nil) {
            topController = topController?.presentedViewController
        }
        
        if let tabbar = topController as? UITabBarController,
           let split = tabbar.viewControllers?[tabbar.selectedIndex] as? UISplitViewController,
           let navigation = split.viewControllers.first as? UINavigationController {
            return navigation.visibleViewController
        }
        
        if let tabbar = topController as? UITabBarController,
           let navigation = tabbar.viewControllers?[tabbar.selectedIndex] as? UINavigationController {
            return navigation.visibleViewController
        }
        
        return topController
    }
    
    func getTabBarController() -> UITabBarController? {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        guard let windowScene = scene as? UIWindowScene else {
            return nil
        }
        
        var topController = windowScene.keyWindow?.rootViewController
        
        while (topController?.presentedViewController != nil) {
            topController = topController?.presentedViewController
        }
        
        return topController as? UITabBarController
    }
    
    func presentChatroom(_ chatroom: Chatroom) {
        guard let tabbar = getTabBarController() else { return }
        
        if let split = tabbar.viewControllers?.first as? UISplitViewController,
           let navigation = split.viewControllers.first as? UINavigationController,
           let chatListVC = navigation.viewControllers.first as? ChatListViewController {
            navigation.popToRootViewController(animated: true)
            Task {
                await chatListVC.presentChatroom(chatroom)
                await chatListVC.selectChatroomRow(chatroom: chatroom)
            }
        }
        
        if let navigation = tabbar.viewControllers?.first as? UINavigationController,
           let chatListVC = navigation.viewControllers.first as? ChatListViewController {
            navigation.popToRootViewController(animated: true)
            Task {
                await chatListVC.presentChatroom(chatroom)
                await chatListVC.selectChatroomRow(chatroom: chatroom)
            }
        }
    }
}
