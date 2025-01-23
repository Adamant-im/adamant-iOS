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
import CommonKit
import AdvancedContextMenuKit
import SwiftUI
import ElegantEmojiPicker

@MainActor
final class ChatDialogManager {
    private let viewModel: ChatViewModel
    private let dialogService: DialogService
    private let emojiService: EmojiService?
    
    private var subscription: AnyCancellable?
    private lazy var contextMenu = AdvancedContextMenuManager()
    
    typealias DidSelectEmojiAction = ((_ emoji: String, _ messageId: String) -> Void)?
    typealias ContextMenuAction = ((_ messageId: String) -> Void)?
    
    init(
        viewModel: ChatViewModel,
        dialogService: DialogService,
        emojiService: EmojiService
    ) {
        self.viewModel = viewModel
        self.dialogService = dialogService
        self.emojiService = emojiService
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
        case let .error(message, supportEmail):
            dialogService.showError(
                withMessage: message,
                supportEmail: supportEmail,
                error: nil
            )
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
        case let .presentMenu(
            presentReactions,
            arg,
            didSelectEmojiDelegate,
            didSelectEmojiAction,
            didPresentMenuAction,
            didDismissMenuAction
        ):
            presentMenu(
                presentReactions: presentReactions,
                arg: arg,
                didSelectEmojiDelegate: didSelectEmojiDelegate,
                didSelectEmojiAction: didSelectEmojiAction,
                didPresentMenuAction: didPresentMenuAction,
                didDismissMenuAction: didDismissMenuAction
            )
        case .dismissMenu:
            dismissMenu()
        case .renameAlert:
            showRenameAlert()
        case .actionMenu:
            showActionMenu()
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
            from: .barButtonItem(sender)
        )
    }
    
    func showActionMenu() {
        let didSelect: ((ShareType) -> Void)? = { [weak self] type in
            self?.viewModel.didSelectMenuAction(type)
        }
        
        dialogService.presentShareAlertFor(
            string: .empty,
            types: [
                .sendTokens,
                .uploadFile,
                .uploadMedia
            ],
            excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
            animated: true,
            from: nil,
            completion: nil,
            didSelect: didSelect
        )
    }
    
    func showSystemPartnerMenu(sender: UIBarButtonItem) {
        guard let address = address else { return }
        
        let didSelect: ((ShareType) -> Void)? = { [weak self] type in
            guard case .partnerQR = type,
                  let partner = self?.viewModel.chatroom?.partner
            else { return }
            
            self?.viewModel.didTapPartnerQR.send(partner)
        }
        
        dialogService.presentShareAlertFor(
            string: address,
            types: [
                .copyToPasteboard,
                .share,
                .partnerQR
            ],
            excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
            animated: true,
            from: sender,
            completion: nil,
            didSelect: didSelect
        )
    }
    
    func showFreeTokenAlert() {
        AlertFactory.freeTokenAlertIfNeed(type: .message)
    }
    
    func showRemoveMessageAlert(id: String) {
        dialogService.showAlert(
            title: .adamant.chat.removeMessage,
            message: nil,
            style: .alert,
            actions: [
                .init(
                    title: .adamant.alert.ok,
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
            title: .adamant.chat.reportMessage,
            message: nil,
            style: .alert,
            actions: [
                .init(
                    title: .adamant.alert.ok,
                    style: .destructive,
                    handler: { [weak self] in
                        self?.viewModel.hideMessage(id: id)
                        self?.dialogService.showToastMessage(.adamant.chat.reportSent)
                    }
                ),
                makeCancelAction()
            ],
            from: nil
        )
    }
    
    func showFailedMessageAlert(id: String, sender: UIAlertController.SourceView?) {
        dialogService.showAlert(
            title: .adamant.alert.retryOrDeleteTitle,
            message: .adamant.alert.retryOrDeleteBody,
            style: .actionSheet,
            actions: [
                makeRetryAction(id: id),
                makeCancelSendingAction(id: id),
                makeCancelAction()
            ],
            from: nil
        )
    }
    
    func showRenameAlert() {
        guard let address = address else { return }
        
        let alert = AlertFactory.makeRenameAlert(
            titleFormat: String(format: .adamant.chat.actionsBody, address),
            placeholder: .adamant.chat.name,
            initialText: viewModel.partnerName
        ) { [weak viewModel] newName in
            viewModel?.setNewName(newName)
        }
        
        dialogService.present(alert, animated: true) { [weak self] in
            self?.dialogService.selectAllTextFields(in: alert)
        }
    }
}

// MARK: Alert actions

private extension ChatDialogManager {
    func makeBlockAction() -> UIAlertAction {
        .init(
            title: .adamant.chat.block,
            style: .destructive
        ) { [weak dialogService, weak viewModel] _ in
            dialogService?.showAlert(
                title: .adamant.chatList.blockUser,
                message: nil,
                style: .alert,
                actions: [
                    .init(
                        title: .adamant.alert.ok,
                        style: .destructive,
                        handler: { viewModel?.blockChat() }
                    ),
                    .init(
                        title: .adamant.alert.cancel,
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
            title: .adamant.chat.rename,
            style: .default
        ) { [weak self] _ in
            self?.showRenameAlert()
        }
    }
    
    func makeShareAction(sender: UIBarButtonItem) -> UIAlertAction {
        .init(
            title: ShareType.share.localized,
            style: .default
        ) { [weak self] _ in
            guard
                let self = self,
                let address = self.address
            else { return }
            
            let didSelect: ((ShareType) -> Void)? = { [weak self] type in
                guard case .partnerQR = type,
                      let partner = self?.viewModel.chatroom?.partner
                else { return }
                
                self?.viewModel.didTapPartnerQR.send(partner)
            }
            
            self.dialogService.presentShareAlertFor(
                string: address,
                types: [
                    .copyToPasteboard,
                    .share,
                    .partnerQR
                ],
                excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                animated: true,
                from: sender,
                completion: nil,
                didSelect: didSelect
            )
        }
    }
    
//    func makeFreeTokensAlertAction() -> UIAlertAction {
//        .init(
//            title: String.adamant.chat.freeTokens,
//            style: .default
//        ) { [weak self] _ in
//            guard let self = self, let url = self.viewModel.freeTokensURL else { return }
//            let safari = SFSafariViewController(url: url)
//            safari.preferredControlTintColor = UIColor.adamant.primary
//            safari.modalPresentationStyle = .overFullScreen
//            self.dialogService.present(safari, animated: true, completion: nil)
//        }
//    }
    
    func showAdmMenuAction(_ adm: AdamantAddress, partnerAddress: String) {
        let shareTypes: [AddressChatShareType] = adm.address == partnerAddress ? [.send] : [.chat, .send]
        let name = adm.name ?? adm.address
        
        let kvsName = viewModel.getKvsName(for: adm.address)
        
        self.dialogService.presentShareAlertFor(
            adm: adm.address,
            name: kvsName ?? name,
            types: shareTypes,
            animated: true,
            from: nil,
            completion: nil
        ) { [weak self] action in
            guard let self = self else { return }
            DispatchQueue.onMainAsync {
                if case .invalid = AdamantUtilities.validateAdamantAddress(address: adm.address) {
                    self.dialogService.showToastMessage(String.adamant.newChat.specifyValidAddressMessage)
                    return
                }
                
                self.viewModel.process(adm: adm, action: action)
            }
        }
    }
    
    func showDummyAlert(for address: String) {
        dialogService.presentDummyChatAlert(
            for: address,
            from: nil,
            canSend: false,
            sendCompletion: nil
        )
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
                showAlert(message: String.adamant.chat.noMailAppWarning)
            }
        } else {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showAlert(message: String.adamant.chat.unsupportedUrlWarning)
            }
        }
    }
    
    func makeRetryAction(id: String) -> UIAlertAction {
        .init(title: .adamant.alert.retry, style: .default) { [weak viewModel] _ in
            viewModel?.retrySendMessage(id: id)
        }
    }
    
    func makeCancelSendingAction(id: String) -> UIAlertAction {
        .init(title: .adamant.alert.delete, style: .default) { [weak viewModel] _ in
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
        .init(title: .adamant.alert.cancel, style: .cancel, handler: nil)
    }
    
    func makeCancelAction() -> AdamantAlertAction {
        .init(title: .adamant.alert.cancel, style: .cancel, handler: nil)
    }
}

// MARK: Context Menu

private extension ChatDialogManager {
    func dismissMenu() {
        Task {
            await contextMenu.dismiss()
        }
    }
    
    func presentMenu(
        presentReactions: Bool,
        arg: ChatContextMenuArguments,
        didSelectEmojiDelegate: ElegantEmojiPickerDelegate?,
        didSelectEmojiAction: DidSelectEmojiAction,
        didPresentMenuAction: ContextMenuAction,
        didDismissMenuAction: ContextMenuAction
    ) {
        contextMenu.didPresentMenuAction = didPresentMenuAction
        contextMenu.didDismissMenuAction = didDismissMenuAction
        
        let reactionsContentView = !presentReactions
        ? nil
        : getUpperContentView(
            messageId: arg.messageId,
            selectedEmoji: arg.selectedEmoji,
            didSelectEmojiAction: didSelectEmojiAction,
            didSelectEmojiDelegate: didSelectEmojiDelegate
        )
        
        let reactionsContentViewSize: CGSize = !presentReactions
        ? .zero
        : getUpperContentViewSize()
        
        contextMenu.presentMenu(
            arg: arg,
            upperView: reactionsContentView,
            upperViewSize: reactionsContentViewSize
        )
    }
    
    func getUpperContentViewSize() -> CGSize {
        .init(width: 335, height: 50)
    }
    
    func getUpperContentView(
        messageId: String,
        selectedEmoji: String?,
        didSelectEmojiAction: DidSelectEmojiAction,
        didSelectEmojiDelegate: ElegantEmojiPickerDelegate?
    ) -> AnyView? {
        var view = ChatReactionsView(
            emojis: getFrequentlySelectedEmojis(selectedEmoji: selectedEmoji),
            selectedEmoji: selectedEmoji,
            messageId: messageId
        )
        view.didSelectEmoji = didSelectEmojiAction
        view.didSelectMore = { [weak self, didSelectEmojiDelegate] in
            let config = ElegantConfiguration(
                showRandom: false,
                showReset: false,
                defaultSkinTone: .Light
            )
            let picker = ElegantEmojiPicker(
                delegate: didSelectEmojiDelegate,
                configuration: config
            )
            self?.contextMenu.presentOver(picker, animated: true)
        }
        return AnyView(view)
    }
    
    func getFrequentlySelectedEmojis(selectedEmoji: String?) -> [String]? {
        var emojis = emojiService?.getFrequentlySelectedEmojis()
        guard let selectedEmoji = selectedEmoji else { return emojis }
        
        if let index = emojis?.firstIndex(of: selectedEmoji) {
            emojis?.remove(at: index)
        }
        emojis?.insert(selectedEmoji, at: 0)
        
        return emojis
    }
}
