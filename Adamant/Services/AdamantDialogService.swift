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

final class AdamantDialogService: DialogService {
    // MARK: Dependencies
    private let router: Router
    private let popupManager = PopupManager()
    private let mailDelegate = MailDelegate()
    private weak var window: UIWindow?
    
    // Configure notifications
    init(router: Router) {
        self.router = router
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
        
        DispatchQueue.onMainAsync { [weak self] in
            self?.getTopmostViewController()?.present(viewController, animated: animated, completion: completion)
        }
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
        DispatchQueue.onMainAsync { [weak popupManager] in
            popupManager?.showProgressAlert(message: message, userInteractionEnabled: enabled)
        }
    }
    
    func dismissProgress() {
        DispatchQueue.onMainAsync { [weak popupManager] in
            popupManager?.dismissAlert()
        }
    }
    
    func showSuccess(withMessage message: String) {
        DispatchQueue.onMainAsync { [weak popupManager] in
            popupManager?.showSuccessAlert(message: message)
        }
    }
    
    func showWarning(withMessage message: String) {
        DispatchQueue.onMainAsync { [weak popupManager] in
            popupManager?.showWarningAlert(message: message)
        }
    }
    
    func showError(withMessage message: String, supportEmail: Bool, error: Error? = nil) {
        DispatchQueue.onMainAsync { [self] in
            internalShowError(withMessage: message, supportEmail: supportEmail, error: error)
        }
    }
    
    private func internalShowError(
        withMessage message: String,
        supportEmail: Bool,
        error: Error? = nil
    ) {
        popupManager.showAdvancedAlert(model: .init(
            icon: #imageLiteral(resourceName: "error"),
            title: .adamantLocalized.alert.error,
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
                title: .adamantLocalized.alert.ok,
                action: .init(id: .zero) { [weak popupManager] in
                    popupManager?.dismissAdvancedAlert()
                }
            )
        ))
    }
    
    func showRichError(error: RichError) {
        showRichError(error: error, supportEmail: nil)
    }
    
    func showRichError(error: RichError, supportEmail: Bool?) {
        switch error.level {
        case .warning:
            showWarning(withMessage: error.message)
        case .error:
            showError(
                withMessage: error.message,
                supportEmail: supportEmail ?? false,
                error: error.internalError
            )
        case .internalError:
            showError(
                withMessage: error.message,
                supportEmail: supportEmail ?? true,
                error: error.internalError
            )
        }
    }
    
    func showRichError(error: Error) {
        showRichError(error: error, supportEmail: nil)
    }
    
    func showRichError(error: Error, supportEmail: Bool?) {
        if let error = error as? RichError {
            showRichError(error: error, supportEmail: supportEmail)
        } else {
            showError(
                withMessage: error.localizedDescription,
                supportEmail: supportEmail ?? true,
                error: error)
        }
    }
    
    func showNoConnectionNotification() {
        DispatchQueue.onMainAsync { [weak popupManager] in
            popupManager?.showNotification(
                icon: #imageLiteral(resourceName: "error"),
                title: .adamantLocalized.alert.noInternetNotificationTitle,
                description: .adamantLocalized.alert.noInternetNotificationBoby,
                autoDismiss: false,
                tapHandler: nil
            )
        }
    }
    
    func dissmisNoConnectionNotification() {
        DispatchQueue.onMainAsync { [weak popupManager] in
            popupManager?.dismissNotification()
        }
    }
    
    private func sendErrorEmail(errorDescription: String) {
        let body = String(
            format: .adamantLocalized.alert.emailErrorMessageBody,
            errorDescription,
            AdamantUtilities.deviceInfo
        )
        
        if let vc = getTopmostViewController() {
            vc.openEmailScreen(
                recipient: AdamantResources.supportEmail,
                subject: .adamantLocalized.alert.emailErrorMessageTitle,
                body: body,
                delegate: mailDelegate
            )
        } else {
            AdamantUtilities.openEmailApp(
                recipient: AdamantResources.supportEmail,
                subject: .adamantLocalized.alert.emailErrorMessageTitle,
                body: body
            )
        }
    }
}

// MARK: - Notifications
extension AdamantDialogService {
    func showNotification(title: String?, message: String?, image: UIImage?, tapHandler: (() -> Void)?) {
        DispatchQueue.onMainAsync { [weak popupManager] in
            popupManager?.showNotification(
                icon: image,
                title: title,
                description: message,
                autoDismiss: true,
                tapHandler: tapHandler
            )
        }
    }
    
    func dismissNotification() {
        DispatchQueue.onMainAsync { [weak popupManager] in
            popupManager?.dismissNotification()
        }
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
        let alert = makeSafeAlertController(
            title: adm,
            message: nil,
            preferredStyle: .actionSheet,
            source: from
        )
        
        let source: ViewSource? = from.map { .view($0) }
        
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
        
        if let sourceView = from {
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
            alert.popoverPresentationController?.canOverlapSourceViewRect = false
        }
        
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    func presentShareAlertFor(string: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIView?, completion: (() -> Void)?) {
        let source: ViewSource? = from.map { .view($0) }
        
        let alert = createShareAlertFor(stringForPasteboard: string, stringForShare: string, stringForQR: string, types: types, excludedActivityTypes: excludedActivityTypes, animated: animated, from: source, completion: completion)
        
        if let sourceView = from {
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
            alert.popoverPresentationController?.canOverlapSourceViewRect = false
        }
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    func presentShareAlertFor(string: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIBarButtonItem?, completion: (() -> Void)?) {
        let source: ViewSource?
        if let from = from {
            source = .barButtonItem(from)
        } else {
            source = nil
        }
        
        let alert = createShareAlertFor(stringForPasteboard: string, stringForShare: string, stringForQR: string, types: types, excludedActivityTypes: excludedActivityTypes, animated: animated, from: source, completion: completion)
        
        if let sourceView = from {
            alert.popoverPresentationController?.barButtonItem = sourceView
        }
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    func presentShareAlertFor(stringForPasteboard: String, stringForShare: String, stringForQR: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIView?, completion: (() -> Void)?) {
        let source: ViewSource? = from.map { .view($0) }
        
        let alert = createShareAlertFor(stringForPasteboard: stringForPasteboard, stringForShare: stringForShare, stringForQR: stringForQR, types: types, excludedActivityTypes: excludedActivityTypes, animated: animated, from: source, completion: completion)
        
        if let sourceView = from {
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
            alert.popoverPresentationController?.canOverlapSourceViewRect = false
        }
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    // Passing sender to second modal window
    private enum ViewSource {
        case view(UIView)
        case barButtonItem(UIBarButtonItem)
        
        var entity: Any {
            switch self {
            case let .view(view):
                return view
            case let .barButtonItem(item):
                return item
            }
        }
    }
    
    private func createShareAlertFor(
        stringForPasteboard: String,
        stringForShare: String,
        stringForQR: String,
        types: [ShareType],
        excludedActivityTypes: [UIActivity.ActivityType]?,
        animated: Bool,
        from: ViewSource?,
        completion: (() -> Void)?
    ) -> UIAlertController {
        let alert = makeSafeAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            source: from?.entity
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
        from: ViewSource?,
        completion: (() -> Void)?
    ) {
        for type in types {
            switch type {
            case .copyToPasteboard:
                alert.addAction(UIAlertAction(title: type.localized , style: .default) { [weak self] _ in
                    UIPasteboard.general.string = stringForPasteboard
                    self?.showToastMessage(String.adamantLocalized.alert.copiedToPasteboardNotification)
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
                    switch AdamantQRTools.generateQrFrom(string: encodedContent ?? stringForQR, withLogo: withLogo) {
                    case .success(let qr):
                        guard let vc = self?.router.get(scene: AdamantScene.Shared.shareQr) as? ShareQrViewController else {
                            fatalError("Can't find ShareQrViewController")
                        }
                        
                        vc.qrCode = qr
                        vc.sharingTip = sharingTip
                        vc.excludedActivityTypes = excludedActivityTypes
                        vc.modalPresentationStyle = .overFullScreen
                        self?.present(vc, animated: true, completion: completion)
                        
                    case .failure(error: let error):
                        self?.showError(
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
        
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
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
            message: String.adamantLocalized.transferAdm.accountNotFoundAlertBody,
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
            message: String.adamantLocalized.transferAdm.accountNotFoundChatAlertBody,
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
        let alert = makeSafeAlertController(
            title: String.adamantLocalized.transferAdm.accountNotFoundAlertTitle(
                for: adm
            ),
            message: message,
            preferredStyle: .alert,
            source: nil
        )
        
        if let url = URL(string: NewChatViewController.faqUrl) {
            let faq = UIAlertAction(
                title: String.adamantLocalized.newChat.whatDoesItMean,
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
                title: String.adamantLocalized.transfer.send,
                style: .default,
                handler: sendCompletion
            )
            alert.addAction(send)
        }
        
        let cancel = UIAlertAction(
            title: String.adamantLocalized.alert.cancel,
            style: .cancel,
            handler: nil
        )
        alert.addAction(cancel)
        
        if let sourceView = from {
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
            alert.popoverPresentationController?.canOverlapSourceViewRect = false
        }
        
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showError(withMessage: error.localizedDescription, supportEmail: true)
        } else {
            showSuccess(withMessage: String.adamantLocalized.alert.done)
        }
    }
    
    func presentGoToSettingsAlert(title: String?, message: String?) {
        let alert = makeSafeAlertController(
            title: title,
            message: message,
            preferredStyle: .alert,
            source: nil
        )
        
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default) { _ in
            DispatchQueue.main.async {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
        alert.modalPresentationStyle = .overFullScreen
        
        DispatchQueue.onMainAsync { [weak self] in
            self?.present(alert, animated: true, completion: nil)
        }
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
    func showAlert(title: String?, message: String?, style: AdamantAlertStyle, actions: [AdamantAlertAction]?, from: Any?) {
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
    
    func showAlert(title: String?, message: String?, style: UIAlertController.Style, actions: [UIAlertAction]?, from: Any?) {
        let alert = makeSafeAlertController(
            title: title,
            message: message,
            preferredStyle: style,
            source: from
        )
        
        if let actions = actions {
            for action in actions {
                alert.addAction(action)
            }
        } else {
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.ok, style: .default))
        }
        
        if let sourceView = from as? UIView {
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
            alert.popoverPresentationController?.canOverlapSourceViewRect = false
        } else if  let barButtonItem = from as? UIBarButtonItem {
            alert.popoverPresentationController?.barButtonItem = barButtonItem
        }
        
        present(alert, animated: true, completion: nil)
    }
}

private class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

/// Its needed to avoid crashes on `actionSheet` alert style on MacOS
private func makeSafeAlertController(
    title: String?,
    message: String?,
    preferredStyle: UIAlertController.Style,
    source: Any?
) -> UIAlertController {
    let style = source == nil && UIScreen.main.traitCollection.userInterfaceIdiom == .pad
        ? .alert
        : preferredStyle
    
    return .init(title: title, message: message, preferredStyle: style)
}
