//
//  SecretWalletsAlertService.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 01.03.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit

@MainActor
final class SecretWalletsAlertService {
    private let dialogService: DialogService
    private let secretWalletsViewModel: SecretWalletsViewModel
    
    init(
        dialogService: DialogService,
        secretWalletsManager: SecretWalletsManagerProtocol
    ) {
        self.dialogService = dialogService
        self.secretWalletsViewModel = .init(secretWalletsManager: secretWalletsManager)
    }
    
    func presentSecretWalletsActionSheet(from sourceView: UIView) {
        var actions = [AdamantAlertAction]()
        let state = secretWalletsViewModel.state
        
        for (index, wallet) in state.wallets.enumerated() {
            let isSelected = (index == state.currentActiveIndex)
            let suffix = isSelected ? " ✓" : ""
            
            let action = AdamantAlertAction(
                title: wallet.name + suffix,
                style: .default
            ) { [weak self] in
                self?.secretWalletsViewModel.pickWallet(at: index)
            }
            actions.append(action)
        }
        
        if state.wallets.count < 6 {
            let enableWalletAction = AdamantAlertAction(
                title: "🪄 Add secret wallet",
                style: .default
            ) { [weak self] in
                self?.showEnableSecretWalletAlert()
            }
            actions.append(enableWalletAction)
        }
        
        let infoAction = AdamantAlertAction(
            title: "💡 Tell me more",
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
            title: nil,
            message: nil,
            style: .actionSheet,
            actions: actions,
            from: source
        )
    }
    
    private func showEnableSecretWalletAlert() {
        let passwordAlert = UIAlertController(
            title: "Enter password to add secret wallet",
            message: nil,
            preferredStyle: .alert
        )
        
        passwordAlert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Password"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        passwordAlert.addAction(cancelAction)
        
        let enableAction = UIAlertAction(title: "Enable", style: .default) { [weak self] _ in
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
            title: "Secret Wallets",
            message: "Secret wallets are encrypted and require a password...",
            preferredStyle: .alert
        )
        infoAlert.addAction(.init(title: "Got it", style: .default))
        
        dialogService.present(infoAlert, animated: true, completion: nil)
    }
}
