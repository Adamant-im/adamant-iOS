//
//  AdamantDialogService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import MessageUI
import PopupKit
import SafariServices
import CommonKit

@MainActor
final class AdamantDialogService: DialogService {
    // MARK: Dependencies
    private let vibroService: VibroService
    private let popupManager = PopupManager()
    private let mailDelegate = MailDelegate()
    
    private weak var window: UIWindow?
    
    nonisolated init(vibroService: VibroService) {
        self.vibroService = vibroService
    }
    
    func setup(window: UIWindow) {
        self.window = window
        popupManager.setup()
    }
}

// MARK: - Modal dialogs
extension AdamantDialogService {
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        viewController.modalPresentationStyle = .overFullScreen
        getTopmostViewController()?.present(viewController, animated: animated, completion: completion)
    }
    
    func getTopmostViewController() -> UIViewController? {
        if var topController = window?.rootViewController {
            if let tab = topController as? UITabBarController, let selected = tab.selectedViewController {
                topController = selected
            }
            
            if let nav = topController as? UINavigationController, let visible = nav.visibleViewController {
                if let presented = visible.presentedViewController {
                    return presented
                } else {
                    return visible
                }
            }
            
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            return topController
        }
        
        return nil
    }
}

// MARK: - Toast
extension AdamantDialogService {
    func showToastMessage(_ message: String) {
        popupManager.showToastMessage(message)
    }
    
    func dismissToast() {
        popupManager.dismissToast()
    }
}

// MARK: - Indicators
extension AdamantDialogService {
    func showProgress(withMessage message: String?, userInteractionEnable enabled: Bool) {
        popupManager.showProgressAlert(message: message, userInteractionEnabled: enabled)
    }
    
    func dismissProgress() {
        popupManager.dismissAlert()
    }
    
    func showSuccess(withMessage message: String) {
        vibroService.applyVibration(.success)
        popupManager.showSuccessAlert(message: message)
    }
    
    func showWarning(withMessage message: String) {
        vibroService.applyVibration(.error)
        popupManager.showWarningAlert(message: message)
    }
    
    func showError(withMessage message: String, supportEmail: Bool, error: Error? = nil) {
        internalShowError(withMessage: message, supportEmail: supportEmail, error: error)
    }
    
    private func internalShowError(
        withMessage message: String,
        supportEmail: Bool,
        error: Error? = nil
    ) {
        vibroService.applyVibration(.error)
        popupManager.showAdvancedAlert(model: .init(
            icon: .asset(named: "error") ?? .init(),
            title: .adamant.alert.error,
            text: message,
            secondaryButton: supportEmail
                ? .init(
                    title: AdamantResources.supportEmail,
                    action: .init(id: .zero) { [weak self] in
                        self?.sendErrorEmail(errorDescription: message)
                        self?.popupManager.dismissAdvancedAlert()
                    }
                )
                : nil,
            primaryButton: .init(
                title: .adamant.alert.ok,
                action: .init(id: .zero) { [weak popupManager] in
                    popupManager?.dismissAdvancedAlert()
                }
            )
        ))
    }
    
    func showRichError(error: RichError) {
        switch error.level {
        case .warning:
            showWarning(withMessage: error.message)
        case .error:
            showError(
                withMessage: error.message,
                supportEmail: false,
                error: error.internalError
            )
        case .internalError:
            showError(
                withMessage: error.message,
                supportEmail: true,
                error: error.internalError
            )
        }
    }
    
    func showRichError(error: Error) {
        if let error = error as? RichError {
            showRichError(error: error)
        } else {
            showError(
                withMessage: error.localizedDescription,
                supportEmail: true,
                error: error
            )
        }
    }
    
    func showNoConnectionNotification() {
        popupManager.showNotification(
            icon: .asset(named: "error"),
            title: .adamant.alert.noInternetNotificationTitle,
            description: .adamant.alert.noInternetNotificationBoby,
            autoDismiss: false,
            tapHandler: nil
        )
    }
    
    func dissmisNoConnectionNotification() {
        popupManager.dismissNotification()
    }
    
    private func sendErrorEmail(errorDescription: String) {
        let body = String(
            format: .adamant.alert.emailErrorMessageBody,
            errorDescription,
            AdamantUtilities.deviceInfo
        )
        
        if let vc = getTopmostViewController() {
            vc.openEmailScreen(
                recipient: AdamantResources.supportEmail,
                subject: .adamant.alert.emailErrorMessageTitle,
                body: body,
                delegate: mailDelegate
            )
        } else {
            AdamantUtilities.openEmailApp(
                recipient: AdamantResources.supportEmail,
                subject: .adamant.alert.emailErrorMessageTitle,
                body: body
            )
        }
    }
}

// MARK: - Notifications
extension AdamantDialogService {
    func showNotification(title: String?, message: String?, image: UIImage?, tapHandler: (() -> Void)?) {
        popupManager.showNotification(
            icon: image,
            title: title,
            description: message,
            autoDismiss: true,
            tapHandler: tapHandler
        )
    }
    
    func dismissNotification() {
        popupManager.dismissNotification()
    }
}

// MAKR: - Activity controllers
extension AdamantDialogService {
    func presentShareAlertFor(
        adm: String,
        name: String,
        types: [AddressChatShareType],
        animated: Bool,
        from: UIView?,
        completion: (() -> Void)?,
        didSelect: ((AddressChatShareType) -> Void)?
    ) {
        let source: UIAlertController.SourceView? = from.map { .view($0) }
        
        let alert = UIAlertController(
            title: adm,
            message: nil,
            preferredStyleSafe: .actionSheet,
            source: source
        )
        
        for type in types {
            alert.addAction(
                UIAlertAction(title: type.localized + name, style: .default) { _ in
                didSelect?(type)
            })
        }
        
        let encodedAddress = AdamantUriTools.encode(
            request: AdamantUri.address(address: adm, params: nil)
        )
        
        addActions(
            to: alert,
            stringForPasteboard: adm,
            stringForShare: adm,
            stringForQR: adm,
            types: [
                .copyToPasteboard,
                .share,
                .generateQr(encodedContent: encodedAddress,
                            sharingTip: adm,
                            withLogo: true
                           )
            ],
            excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
            from: source,
            completion: nil
        )
        
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    func presentShareAlertFor(string: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIView?, completion: (() -> Void)?) {
        let source: UIAlertController.SourceView? = from.map { .view($0) }
        
        let alert = createShareAlertFor(stringForPasteboard: string, stringForShare: string, stringForQR: string, types: types, excludedActivityTypes: excludedActivityTypes, animated: animated, from: source, completion: completion)
        
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    func presentShareAlertFor(string: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIBarButtonItem?, completion: (() -> Void)?) {
        let source: UIAlertController.SourceView? = from.map { .barButtonItem($0) }
        
        let alert = createShareAlertFor(stringForPasteboard: string, stringForShare: string, stringForQR: string, types: types, excludedActivityTypes: excludedActivityTypes, animated: animated, from: source, completion: completion)
        
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    func presentShareAlertFor(stringForPasteboard: String, stringForShare: String, stringForQR: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIView?, completion: (() -> Void)?) {
        let source: UIAlertController.SourceView? = from.map { .view($0) }
        
        let alert = createShareAlertFor(stringForPasteboard: stringForPasteboard, stringForShare: stringForShare, stringForQR: stringForQR, types: types, excludedActivityTypes: excludedActivityTypes, animated: animated, from: source, completion: completion)
        
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    private func createShareAlertFor(
        stringForPasteboard: String,
        stringForShare: String,
        stringForQR: String,
        types: [ShareType],
        excludedActivityTypes: [UIActivity.ActivityType]?,
        animated: Bool,
        from: UIAlertController.SourceView?,
        completion: (() -> Void)?
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyleSafe: .actionSheet,
            source: from
        )

        addActions(to: alert, stringForPasteboard: stringForPasteboard, stringForShare: stringForShare, stringForQR: stringForQR, types: types, excludedActivityTypes: excludedActivityTypes, from: from, completion: completion)
        
        return alert
    }
        
    private func addActions(
        to alert: UIAlertController,
        stringForPasteboard: String,
        stringForShare: String,
        stringForQR: String,
        types: [ShareType],
        excludedActivityTypes: [UIActivity.ActivityType]?,
        from: UIAlertController.SourceView?,
        completion: (() -> Void)?
    ) {
        for type in types {
            switch type {
            case .copyToPasteboard:
                alert.addAction(UIAlertAction(title: type.localized , style: .default) { [weak self] _ in
                    UIPasteboard.general.string = stringForPasteboard
                    self?.showToastMessage(String.adamant.alert.copiedToPasteboardNotification)
                })
                
            case .share:
                alert.addAction(UIAlertAction(title: type.localized, style: .default) { [weak self] _ in
                    let vc = UIActivityViewController(activityItems: [stringForShare], applicationActivities: nil)
                    vc.excludedActivityTypes = excludedActivityTypes
                    
                    switch from {
                    case .view(let view)?:
                        vc.popoverPresentationController?.sourceView = view
                        vc.popoverPresentationController?.sourceRect = view.bounds
                        vc.popoverPresentationController?.canOverlapSourceViewRect = false
                        
                    case .barButtonItem(let item)?:
                        vc.popoverPresentationController?.barButtonItem = item
                        
                    default:
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            vc.popoverPresentationController?.sourceView = alert.view
                            vc.popoverPresentationController?.sourceRect = alert.view.bounds
                            vc.popoverPresentationController?.canOverlapSourceViewRect = false
                        }
                    }
                    vc.modalPresentationStyle = .overFullScreen
                    self?.present(vc, animated: true, completion: completion)
                })
                
            case .generateQr(let encodedContent, let sharingTip, let withLogo):
                alert.addAction(UIAlertAction(title: type.localized, style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    
                    switch AdamantQRTools.generateQrFrom(
                        string: encodedContent ?? stringForQR,
                        withLogo: withLogo
                    ) {
                    case .success(let qr):
                        let vc = ShareQrViewController(dialogService: self)
                        vc.qrCode = qr
                        vc.sharingTip = sharingTip
                        vc.excludedActivityTypes = excludedActivityTypes
                        vc.modalPresentationStyle = .overFullScreen
                        present(vc, animated: true, completion: completion)
                        
                    case .failure(error: let error):
                        showError(
                            withMessage: error.localizedDescription,
                            supportEmail: true,
                            error: error
                        )
                    }
                })
                
            case .saveToPhotolibrary(let image):
                let action = UIAlertAction(title: type.localized, style: .default) { [weak self] _ in
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.image(_:didFinishSavingWithError:contextInfo:)), nil)
                }
                
                alert.addAction(action)
            }
        }
        
        alert.addAction(UIAlertAction(title: String.adamant.alert.cancel, style: .cancel, handler: nil))
    }
    
    func presentDummyAlert(
        for adm: String,
        from: UIView?,
        canSend: Bool,
        sendCompletion: ((UIAlertAction) -> Void)?
    ) {
        presentDummyAlert(
            for: adm,
            from: from,
            canSend: canSend,
            message: String.adamant.transferAdm.accountNotFoundAlertBody,
            sendCompletion: sendCompletion
        )
    }
    
    func presentDummyChatAlert(
        for adm: String,
        from: UIView?,
        canSend: Bool,
        sendCompletion: ((UIAlertAction) -> Void)?
    ) {
        presentDummyAlert(
            for: adm,
            from: from,
            canSend: canSend,
            message: String.adamant.transferAdm.accountNotFoundChatAlertBody,
            sendCompletion: sendCompletion
        )
    }
    
    func presentDummyAlert(
        for adm: String,
        from: UIView?,
        canSend: Bool,
        message: String,
        sendCompletion: ((UIAlertAction) -> Void)?
    ) {
        let alert = UIAlertController(
            title: String.adamant.transferAdm.accountNotFoundAlertTitle(
                for: adm
            ),
            message: message,
            preferredStyleSafe: .alert,
            source: from.map { .view($0) }
        )
        
        if let url = URL(string: NewChatViewController.faqUrl) {
            let faq = UIAlertAction(
                title: String.adamant.newChat.whatDoesItMean,
                style: UIAlertAction.Style.default) { [weak self] _ in
                    let safari = SFSafariViewController(url: url)
                    safari.preferredControlTintColor = UIColor.adamant.primary
                    safari.modalPresentationStyle = .overFullScreen
                    self?.present(safari, animated: true, completion: nil)
                }
            alert.addAction(faq)
        }
        
        if canSend {
            let send = UIAlertAction(
                title: String.adamant.transfer.send,
                style: .default,
                handler: sendCompletion
            )
            alert.addAction(send)
        }
        
        let cancel = UIAlertAction(
            title: String.adamant.alert.cancel,
            style: .cancel,
            handler: nil
        )
        
        alert.addAction(cancel)
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showError(withMessage: error.localizedDescription, supportEmail: true)
        } else {
            showSuccess(withMessage: String.adamant.alert.done)
        }
    }
    
    func presentGoToSettingsAlert(title: String?, message: String?) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyleSafe: .alert,
            source: nil
        )
        
        alert.addAction(UIAlertAction(title: String.adamant.alert.settings, style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        })
        
        alert.addAction(UIAlertAction(title: String.adamant.alert.cancel, style: .cancel, handler: nil))
        alert.modalPresentationStyle = .overFullScreen
        
        present(alert, animated: true, completion: nil)
    }
}

fileprivate extension AdamantAlertStyle {
    func asUIAlertControllerStyle() -> UIAlertController.Style {
        switch self {
        case .alert:
            return .alert
        case .actionSheet:
            return .actionSheet
        }
    }
}

fileprivate extension AdamantAlertAction {
    func asUIAlertAction() -> UIAlertAction {
        let handler = self.handler
        return UIAlertAction(title: self.title, style: self.style, handler: { _ in handler?() })
    }
}

extension AdamantDialogService {
    func showAlert(title: String?, message: String?, style: AdamantAlertStyle, actions: [AdamantAlertAction]?, from: UIAlertController.SourceView?) {
        switch style {
        case .alert, .actionSheet:
            let uiStyle = style.asUIAlertControllerStyle()
            if let actions = actions {
                let uiActions: [UIAlertAction] = actions.map { $0.asUIAlertAction() }
                
                showAlert(title: title, message: message, style: uiStyle, actions: uiActions, from: from)
            } else {
                showAlert(title: title, message: message, style: uiStyle, actions: nil, from: from)
            }
        }
    }
    
    func showAlert(title: String?, message: String?, style: UIAlertController.Style, actions: [UIAlertAction]?, from: UIAlertController.SourceView?) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyleSafe: style,
            source: from
        )
        
        if let actions = actions {
            for action in actions {
                alert.addAction(action)
            }
        } else {
            alert.addAction(UIAlertAction(title: String.adamant.alert.ok, style: .default))
        }
        
        present(alert, animated: true, completion: nil)
    }
}

private class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension AdamantDialogService {
    func selectAllTextFields(in alert: UIAlertController) {
        alert.textFields?.forEach { textField in
            textField.selectedTextRange = textField.textRange(
                from: textField.beginningOfDocument,
                to: textField.endOfDocument
            )
        }
    }
}
