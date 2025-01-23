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
    static func freeTokenAlertIfNeed(type: FreeTokensAlertType) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let accountService = appDelegate.container.resolve(AccountService.self)!
        let currentBalance = accountService.account?.balance
        if currentBalance ?? 0.0 < AdamantApiService.KvsFee {
            showFreeTokenAlert(type: type, url: accountService.account?.address ?? "")
        }
    }
    static func showFreeTokenAlert(type: FreeTokensAlertType, url: String) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = .alert + 1
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        let alert = UIAlertController(
            title: "",
            message: type.alertMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(makeFreeTokensAlertAction(url: url, window: window))
        alert.addAction(makeCancelAction(window: window))
        alert.modalPresentationStyle = .overFullScreen

        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    private static func makeFreeTokensAlertAction(url: String, window: UIWindow) -> UIAlertAction {
        .init(
            title: String.adamant.chat.freeTokens,
            style: .default
        ) { _ in
            guard let url = freeTokensURL(url: url) else { return }
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            
            window.rootViewController?.present(safari, animated: true)
        }
    }
    
    private static func makeCancelAction(window: UIWindow) -> UIAlertAction {
        .init(
            title: .adamant.alert.cancel,
            style: .cancel
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
enum FreeTokensAlertType {
    case contacts
    case message
    case notification
    
    var alertMessage: String {
            switch self {
            case .contacts:
                return String.adamant.chat.freeTokensContacts
            case .message:
                return String.adamant.chat.freeTokensMessage
            case .notification:
                return String.adamant.chat.freeTokensNotification
            }
        }
}
