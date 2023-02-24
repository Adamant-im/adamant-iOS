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

@MainActor
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
            dialogService.showToastMessage(message)
        case let .alert(message):
            showAlert(message: message)
        case let .error(message):
            dialogService.showError(withMessage: message, error: nil)
        case let .warning(message):
            dialogService.showWarning(withMessage: message)
        case let .richError(error):
            dialogService.showRichError(error: error)
        case let .menu(sender):
            showMenu(sender: sender)
        case .freeTokenAlert:
            showFreeTokenAlert()
        case let .removeMessageAlert(id):
            showRemoveMessageAlert(id: id)
        case let .reportMessageAlert(id):
            showReportMessageAlert(id: id)
        case let .admMenu(address, partnerAddress):
            showAdmMenuAction(address, partnerAddress: partnerAddress)
        case let .dummy(address):
            showDummyAlert(for: address)
        case let .url(url):
            showUrl(url)
        case let .progress(show):
            setProgress(show)
        case let .failedMessageAlert(id, sender):
            showFailedMessageAlert(id: id, sender: sender)
        }
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
    
    func showRemoveMessageAlert(id: String) {
        dialogService.showAlert(
            title: .adamantLocalized.chat.removeMessage,
            message: nil,
            style: .alert,
            actions: [
                .init(
                    title: .adamantLocalized.alert.ok,
                    style: .destructive,
                    handler: { [weak viewModel] in viewModel?.hideMessage(id: id) }
                ),
                makeCancelAction()
            ],
            from: nil
        )
    }
    
    func showReportMessageAlert(id: String) {
        dialogService.showAlert(
            title: .adamantLocalized.chat.reportMessage,
            message: nil,
            style: .alert,
            actions: [
                .init(
                    title: .adamantLocalized.alert.ok,
                    style: .destructive,
                    handler: { [weak self] in
                        self?.viewModel.hideMessage(id: id)
                        self?.dialogService.showToastMessage(.adamantLocalized.chat.reportSent)
                    }
                ),
                makeCancelAction()
            ],
            from: nil
        )
    }
    
    func showFailedMessageAlert(id: String, sender: Any) {
        dialogService.showAlert(
            title: .adamantLocalized.alert.retryOrDeleteTitle,
            message: .adamantLocalized.alert.retryOrDeleteBody,
            style: .actionSheet,
            actions: [
                makeRetryAction(id: id),
                makeCancelSendingAction(id: id),
                makeCancelAction()
            ],
            from: sender
        )
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
            textField.text = viewModel?.partnerName
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
    
    func showAdmMenuAction(_ adm: AdamantAddress, partnerAddress: String) {
        let shareTypes: [AddressChatShareType] = adm.address == partnerAddress ? [.send] : [.chat, .send]
        let name = adm.name ?? adm.address
        
        self.dialogService.presentShareAlertFor(
            adm: adm.address,
            name: name,
            types: shareTypes,
            animated: true,
            from: nil,
            completion: nil
        ) { [weak self] action in
            guard let self = self else { return }
            DispatchQueue.onMainAsync {
                if case .invalid = AdamantUtilities.validateAdamantAddress(address: adm.address) {
                    self.dialogService.showToastMessage(String.adamantLocalized.newChat.specifyValidAddressMessage)
                    return
                }
                
                self.viewModel.process(adm: adm, action: action)
            }
        }
    }
    
    func showDummyAlert(for address: String) {
        let alert = UIAlertController(
            title: nil,
            message: AccountsProviderError.notInitiated(address: address).localized,
            preferredStyle: .alert
        )
        
        let faq = UIAlertAction(title: String.adamantLocalized.newChat.whatDoesItMean, style: .default, handler: { [weak dialogService] _ in
            guard let url = URL(string: NewChatViewController.faqUrl) else {
                return
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            dialogService?.present(safari, animated: true, completion: nil)
        })
        
        alert.addAction(faq)
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.ok, style: .cancel, handler: nil))
        
        alert.modalPresentationStyle = .overFullScreen
        dialogService.present(alert, animated: true, completion: nil)
    }
    
    func showUrl(_ url: URL) {
        if url.absoluteString.starts(with: "http") {
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            dialogService.present(safari, animated: true, completion: nil)
        } else if url.absoluteString.starts(with: "mailto") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showAlert(message: String.adamantLocalized.chat.noMailAppWarning)
            }
        } else {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showAlert(message: String.adamantLocalized.chat.unsupportedUrlWarning)
            }
        }
    }
    
    func makeRetryAction(id: String) -> UIAlertAction {
        .init(title: .adamantLocalized.alert.retry, style: .default) { [weak viewModel] _ in
            viewModel?.retrySendMessage(id: id)
        }
    }
    
    func makeCancelSendingAction(id: String) -> UIAlertAction {
        .init(title: .adamantLocalized.alert.delete, style: .default) { [weak viewModel] _ in
            viewModel?.cancelMessage(id: id)
        }
    }
    
    func setProgress(_ show: Bool) {
        if show {
            dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        } else {
            dialogService.dismissProgress()
        }
    }
    
    func makeCancelAction() -> UIAlertAction {
        .init(title: .adamantLocalized.alert.cancel, style: .cancel, handler: nil)
    }
    
    func makeCancelAction() -> AdamantAlertAction {
        .init(title: .adamantLocalized.alert.cancel, style: .cancel, handler: nil)
    }
}
