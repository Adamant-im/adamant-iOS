//
//  FreeTokensAlertManager.swift
//  Adamant
//
//  Created by Владимир Клевцов on 23.1.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import UIKit
import SafariServices
import CommonKit

enum AlertPresenter {
    @MainActor
    static func freeTokenAlertIfNeed() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let accountService = appDelegate.container.resolve(AccountService.self)!
        let currentBalance = accountService.account?.balance
        if currentBalance ?? 0.0 < AdamantApiService.KvsFee {
            showFreeTokenAlert(url: accountService.account?.address ?? "")
        }
    }
    static func showFreeTokenAlert(url: String) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = .alert + 1
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        let alert = UIAlertController(
            title: "Чтобы начать общение, получите бесплатные монеты или пополните баланс ADM другим способом.",
            message: /*String.adamant.chat.freeTokensMessage*/"АДАМАНТ — децентрализованный мессенджер на блокчейне. Поэтому каждое действие, включая отправку сообщения или сохранение адресной книги, имеет комиссию сети 0.001 ADM",
            preferredStyle: .alert
        )
        
        alert.addAction(makeFreeTokensAlertAction(url: url, window: window))
        alert.addAction(mackBuyTokensAction())
        alert.addAction(makeCancelAction(window: window))
        alert.modalPresentationStyle = .overFullScreen

        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    private static func makeFreeTokensAlertAction(url: String, window: UIWindow) -> UIAlertAction {
        let action = UIAlertAction(
            title: /*String.adamant.chat.freeTokens*/"🎁 Бесплатные монеты",
            style: .destructive
        ) { _ in
            guard let url = freeTokensURL(url: url) else { return }
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            
            window.rootViewController?.present(safari, animated: true)
        }
        return action
    }
    private static func mackBuyTokensAction() -> UIAlertAction {
        .init(
            title: "Купить ADM",
            style: .default
        ) { _ in
        }
    }
    private static func makeCancelAction(window: UIWindow) -> UIAlertAction {
        .init(
            title: .adamant.alert.cancel,
            style: .default
        ) { _ in
            window.isHidden = true
        }
    }
    private static func freeTokensURL(url: String) -> URL? {
        let urlString: String = .adamant.wallets.getFreeTokensUrl(for: url)
        let url = URL(string: urlString)
        
        return url
    }
}
//enum FreeTokensAlertType {
//    case contacts
//    case message
//    case notification
//    
//    var alertMessage: String {
//            switch self {
//            case .contacts:
//                return String.adamant.chat.freeTokensContacts
//            case .message:
//                return String.adamant.chat.freeTokensMessage
//            case .notification:
//                return String.adamant.chat.freeTokensNotification
//            }
//        }
//}
