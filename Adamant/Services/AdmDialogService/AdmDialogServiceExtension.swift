//
//  AdmDialogServiceExtent.swift
//  Adamant
//
//  Created by Владимир Клевцов on 25.1.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import UIKit
import SafariServices

extension AdamantDialogService {
    @MainActor
    func makeRenameAlert(
        titleFormat: String,
        initialText: String?,
        needToPresent: Bool?,
        url: String?,
        showVC: @escaping () -> Void,
        onRename: @escaping (String) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: titleFormat,
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = .adamant.chat.name
            textField.autocapitalizationType = .words
            textField.text = initialText
        }
        
        let renameAction = UIAlertAction(
            title: .adamant.chat.rename,
            style: .default
        ) { _ in
            guard
                let textField = alert.textFields?.first,
                let newName = textField.text,
                !newName.isEmpty
            else { return }
            
            onRename(newName)
            if !(needToPresent ?? true) {
                self.showFreeTokenAlert(url: url, type: .contacts, showVC: showVC)
            }
        }
        
        alert.addAction(renameAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.modalPresentationStyle = .overFullScreen
        return alert
    }
    
    @MainActor
    func showFreeTokenAlert(url: String?, type: FreeTokensAlertType, showVC: @escaping () -> Void) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = .alert + 1
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        
        let alert = UIAlertController(
            title: type.alertTitle,
            message: .adamant.chat.freeTokensMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(makeFreeTokensAlertAction(url: url, window: window))
        alert.addAction(mackBuyTokensAction(action: showVC))
        alert.addAction(makeCancelAction(window: window))
        alert.modalPresentationStyle = .overFullScreen
        
        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    private func makeFreeTokensAlertAction(url: String?, window: UIWindow) -> UIAlertAction {
        let action = UIAlertAction(
            title: .adamant.chat.freeTokens,
            style: .destructive
        ) { _ in
            guard let url = self.freeTokensURL(url: url) else { return }
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            
            window.rootViewController?.present(safari, animated: true)
        }
        return action
    }
    private func mackBuyTokensAction(action: @escaping () -> Void) -> UIAlertAction {
        .init(
            title: .adamant.chat.freeTokensBuyADM,
            style: .default
        ) {  _ in
            action()
        }
    }
    private func makeCancelAction(window: UIWindow) -> UIAlertAction {
        .init(
            title: .adamant.alert.cancel,
            style: .default
        ) { _ in
            window.isHidden = true
        }
    }
    private func freeTokensURL(url: String?) -> URL? {
        guard let url = url else {
            return nil
        }
        let urlString: String = .adamant.wallets.getFreeTokensUrl(for: url)
        let tokenUrl = URL(string: urlString)
        
        return tokenUrl
    }
}

enum FreeTokensAlertType {
    case contacts
    case message
    case notification
    
    var alertTitle: String {
        switch self {
        case .contacts:
            return .adamant.chat.freeTokensTitleBook
        case .message:
            return .adamant.chat.freeTokensTitleChat
        case .notification:
            return .adamant.chat.freeTokensTitleNotification
        }
    }
}
