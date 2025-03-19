//
//  SecretWalletsAlertService.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 01.03.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit

@MainActor
final class SecretWalletsAlertMenuView {
    private let dialogService: DialogService
    private let secretWalletsViewModel: SecretWalletsViewModel
    
    init(
        dialogService: DialogService,
        secretWalletsViewModel: SecretWalletsViewModel
    ) {
        self.dialogService = dialogService
        self.secretWalletsViewModel = secretWalletsViewModel
    }
    
    func presentSecretWalletsActionSheet(from sourceView: UIView) {
        var actions = [AdamantAlertAction]()
        let state = secretWalletsViewModel.state
        
        for (index, wallet) in state.wallets.enumerated() {
            let isSelected = index == state.currentActiveIndex
            let walletName = isSelected ? "[ " + wallet.name + " ]" : wallet.name
            
            let action = AdamantAlertAction(
                title: walletName,
                style: .default
            ) { [weak self] in
                self?.secretWalletsViewModel.pickWallet(at: index)
            }
            actions.append(action)
        }
        
        if state.wallets.count < 6 {
            let enableWalletAction = AdamantAlertAction(
                title: String.localized("SecretWallets.Menu.AddSecretWallet", comment: "Secret wallet menu: add secret wallet"),
                style: .default
            ) { [weak self] in
                self?.showEnableSecretWalletAlert()
            }
            actions.append(enableWalletAction)
        }
        
        let infoAction = AdamantAlertAction(
            title: String.localized("SecretWallets.Menu.TellMeMore", comment: "Secret wallet menu: tell me more"),
            style: .default
        ) { [weak self] in
            self?.showSecretWalletInfoAlert()
        }
        actions.append(infoAction)
        
        let cancelAction = AdamantAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        )
        actions.append(cancelAction)
        
        let source: UIAlertController.SourceView = .view(sourceView)
        dialogService.showAlert(
            title: String.localized("SecretWallets.Menu.Title", comment: "Secret wallet menu: title"),
            message: nil,
            style: .actionSheet,
            actions: actions,
            from: source
        )
    }
    
    private func showEnableSecretWalletAlert() {
        let passwordAlert = UIAlertController(
            title: String.localized("SecretWallets.Menu.AddSecretWallet.Title", comment: "Add secret wallet title"),
            message: nil,
            preferredStyle: .alert
        )
        
        passwordAlert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Password"
        }
        
        let cancelAction = UIAlertAction(title: String.localized("Cancel", comment:  "Cancel adding password"), style: .cancel)
        passwordAlert.addAction(cancelAction)
        
        let enableAction = UIAlertAction(title: String.localized("SecretWallets.Menu.AddSecretWallet.Add", comment: "Confirm adding secret password"), style: .default) { [weak self] _ in
            guard
                let self = self,
                let password = passwordAlert.textFields?.first?.text,
                !password.isEmpty
            else {
                return
            }
            self.secretWalletsViewModel.createSecretWallet(password: password)
        }
        passwordAlert.addAction(enableAction)
        
        dialogService.present(passwordAlert, animated: true, completion: nil)
    }
    
    private func showSecretWalletInfoAlert() {
        let infoAlert = UIAlertController(
            title: String.localized("SecretWallets.Menu.TellMeMore.Title", comment: "Tell me more about secret wallets"),
            message: String.localized("SecretWallets.Menu.TellMeMore.Subtitle", comment: "Subtitle for tell me more alert"),
            preferredStyle: .alert
        )
        infoAlert.addAction(.init(title: String.localized("Cancel"), style: .cancel))
        
        let learnMoreAction = UIAlertAction(title: String.localized("SecretWallets.Menu.TellMeMore.LearnMore", comment: "Learn more about secret wallets") , style: .default) { _ in
            if let url = URL(string: "http://news.adamant.im/") {
                UIApplication.shared.open(url)
            }
        }
        infoAlert.addAction(learnMoreAction)
        
        dialogService.present(infoAlert, animated: true, completion: nil)
    }
}
