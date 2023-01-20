//
//  ChatAlertManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import Combine
import SafariServices

final class ChatDialogManager {
    private let viewModel: ChatViewModel
    private let dialogService: DialogService
    
    private var subscription: AnyCancellable?
    
    init(viewModel: ChatViewModel, dialogService: DialogService) {
        self.viewModel = viewModel
        self.dialogService = dialogService
        subscription = viewModel.dialog.sink { [weak self] in self?.showDialog($0) }
    }
}

private extension ChatDialogManager {
    var address: String? {
        viewModel.chatroom?.partner?.address
    }
    
    var encodedAddress: String? {
        guard let partner = viewModel.chatroom?.partner, let address = address else { return nil }
        
        return AdamantUriTools.encode(request: AdamantUri.address(
            address: address,
            params: partner.name.map { [.label($0)] }
        ))
    }
    
    func showDialog(_ dialog: ChatDialog) {
        switch dialog {
        case let .toast(message):
            showToast(message: message)
        case let .alert(message):
            showAlert(message: message)
        case let .error(message):
            showError(message: message)
        case let .richError(error):
            showRichError(error: error)
        case let .menu(sender):
            showMenu(sender: sender)
        case .freeTokenAlert:
            showFreeTokenAlert()
        }
    }
    
    func showToast(message: String) {
        dialogService.showToastMessage(message)
    }
    
    func showAlert(message: String) {
        dialogService.showAlert(
            title: nil,
            message: message,
            style: AdamantAlertStyle.alert,
            actions: nil,
            from: nil
        )
    }
    
    func showError(message: String) {
        dialogService.showError(withMessage: message, error: nil)
    }
    
    func showRichError(error: RichError) {
        dialogService.showRichError(error: error)
    }
    
    func showMenu(sender: UIBarButtonItem) {
        guard let partner = viewModel.chatroom?.partner else { return }
        guard !partner.isSystem else { return showSystemPartnerMenu(sender: sender) }
        
        dialogService.showAlert(
            title: nil,
            message: nil,
            style: .actionSheet,
            actions: [
                makeBlockAction(),
                makeShareAction(sender: sender),
                makeRenameAction(),
                makeCancelAction()
            ],
            from: sender
        )
    }
    
    func showSystemPartnerMenu(sender: UIBarButtonItem) {
        guard let address = address, let encodedAddress = encodedAddress else { return }
        
        dialogService.presentShareAlertFor(
            string: address,
            types: [
                .copyToPasteboard,
                .share,
                .generateQr(
                    encodedContent: encodedAddress,
                    sharingTip: address,
                    withLogo: true
                )
            ],
            excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
            animated: true,
            from: sender,
            completion: nil
        )
    }
    
    func showFreeTokenAlert() {
        let alert = UIAlertController(
            title: "",
            message: String.adamantLocalized.chat.freeTokensMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(makeFreeTokensAlertAction())
        alert.addAction(makeCancelAction())
        alert.modalPresentationStyle = .overFullScreen
        dialogService.present(alert, animated: true, completion: nil)
    }
}

// MARK: Alert actions

private extension ChatDialogManager {
    func makeBlockAction() -> UIAlertAction {
        .init(
            title: .adamantLocalized.chat.block,
            style: .destructive
        ) { [weak dialogService, weak viewModel] _ in
            dialogService?.showAlert(
                title: .adamantLocalized.chatList.blockUser,
                message: nil,
                style: .alert,
                actions: [
                    .init(
                        title: .adamantLocalized.alert.ok,
                        style: .destructive,
                        handler: { viewModel?.blockChat() }
                    ),
                    .init(
                        title: .adamantLocalized.alert.cancel,
                        style: .default,
                        handler: nil
                    )
                ],
                from: nil
            )
        }
    }
    
    func makeRenameAction() -> UIAlertAction {
        .init(
            title: .adamantLocalized.chat.rename,
            style: .default
        ) { [weak self] _ in
            guard let alert = self?.makeRenameAlert() else { return }
            self?.dialogService.present(alert, animated: true, completion: nil)
        }
    }
    
    func makeRenameAlert() -> UIAlertController? {
        guard let address = address else { return nil }
        
        let alert = UIAlertController(
            title: .init(format: .adamantLocalized.chat.actionsBody, address),
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addTextField { [weak viewModel] textField in
            textField.placeholder = .adamantLocalized.chat.name
            textField.autocapitalizationType = .words
            textField.text = viewModel?.partnerName.value
        }
        
        let renameAction = UIAlertAction(
            title: .adamantLocalized.chat.rename,
            style: .default
        ) { [weak viewModel] _ in
            guard
                let textField = alert.textFields?.first,
                let newName = textField.text
            else { return }
            
            viewModel?.setNewName(newName)
        }
        
        alert.addAction(renameAction)
        alert.addAction(makeCancelAction())
        alert.modalPresentationStyle = .overFullScreen
        return alert
    }
    
    func makeShareAction(sender: UIBarButtonItem) -> UIAlertAction {
        .init(
            title: ShareType.share.localized,
            style: .default
        ) { [weak self] _ in
            guard
                let self = self,
                let address = self.address,
                let encodedAddress = self.encodedAddress
            else { return }
            
            self.dialogService.presentShareAlertFor(
                string: address,
                types: [
                    .copyToPasteboard,
                    .share,
                    .generateQr(
                        encodedContent: encodedAddress,
                        sharingTip: address,
                        withLogo: true
                    )
                ],
                excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                animated: true,
                from: sender,
                completion: nil
            )
        }
    }
    
    func makeFreeTokensAlertAction() -> UIAlertAction {
        .init(
            title: String.adamantLocalized.chat.freeTokens,
            style: .default
        ) { [weak self] _ in
            guard let self = self, let url = self.viewModel.freeTokensURL else { return }
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            self.dialogService.present(safari, animated: true, completion: nil)
        }
    }
    
    func makeCancelAction() -> UIAlertAction {
        .init(title: .adamantLocalized.alert.cancel, style: .cancel, handler: nil)
    }
}
