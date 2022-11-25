//
//  AdamantDialogService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import FTIndicator
import PMAlertController
import MessageUI

class AdamantDialogService: DialogService {
    // MARK: Dependencies
    var router: Router!
    
    fileprivate var mailDelegate: MailDelegate = {
        MailDelegate()
    }()
    
    // Configure notifications
    init() {
        FTIndicator.setIndicatorStyle(.extraLight)
        
        FTNotificationIndicator.setDefaultDismissTime(4)
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
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
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
        FTIndicator.showToastMessage(message)
    }
    
    func dismissToast() {
        FTIndicator.dismissToast()
    }
}

// MARK: - Indicators
extension AdamantDialogService {
    func showProgress(withMessage message: String?, userInteractionEnable enabled: Bool) {
        FTIndicator.showProgress(withMessage: message, userInteractionEnable: enabled)
    }
    
    func dismissProgress() {
        DispatchQueue.onMainAsync {
            FTIndicator.dismissProgress()
        }
    }
    
    func showSuccess(withMessage message: String) {
        FTIndicator.showSuccess(withMessage: message)
    }
    
    func showWarning(withMessage message: String) {
        FTIndicator.showError(withMessage: message)
    }
    
    func showError(withMessage message: String, error: Error? = nil) {
        DispatchQueue.onMainAsync { [weak self] in
            self?.internalShowError(withMessage: message, error: error)
        }
    }
    
    private func internalShowError(withMessage message: String, error: Error? = nil) {
        FTIndicator.dismissProgress()
        
        let alertVC = PMAlertController(title: String.adamantLocalized.alert.error, description: message, image: #imageLiteral(resourceName: "error"), style: .alert)
        
        alertVC.gravityDismissAnimation = false
        alertVC.alertTitle.textColor = UIColor.adamant.primary
        alertVC.alertDescription.textColor = UIColor.adamant.secondary
        alertVC.alertTitle.font = UIFont.systemFont(ofSize: 20)
        alertVC.alertDescription.font = UIFont.systemFont(ofSize: 14, weight: .light)
        alertVC.headerViewHeightConstraint.constant = 50
        
        let supportBtn = PMAlertAction(title: AdamantResources.supportEmail, style: .default) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let dialogService = self, var presenter = dialogService.getTopmostViewController() else {
                    print("Lost connecting with dialog service")
                    return
                }
                
                // Fix issue when PMAlertController is still top ViewController
                if presenter is PMAlertController, let vc = presenter.presentingViewController {
                    presenter = vc
                }
                
                let body: String
                
                if let error = error {
                    let errorDescription = String(describing: error)
                    body = String(format: String.adamantLocalized.alert.emailErrorMessageBodyWithDescription, message,
                        errorDescription,
                        AdamantUtilities.deviceInfo
                    )
                } else {
                    body = String(
                        format: String.adamantLocalized.alert.emailErrorMessageBody,
                        message,
                        AdamantUtilities.deviceInfo
                    )
                }
                
                presenter.openEmailScreen(
                    recipient: AdamantResources.supportEmail,
                    subject: .adamantLocalized.alert.emailErrorMessageTitle,
                    body: body,
                    delegate: dialogService.mailDelegate
                )
            }
        }
        
        supportBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        supportBtn.setTitleColor(UIColor(hex: "#00B6FF"), for: .normal)
        supportBtn.separator.isHidden = true
        
        alertVC.addAction(supportBtn)
        
        let okBtn = PMAlertAction(title: String.adamantLocalized.alert.ok, style: .default)
        
        okBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        okBtn.setTitleColor(UIColor.white, for: .normal)
        okBtn.backgroundColor = UIColor.adamant.secondary
        alertVC.addAction(okBtn)
        
        alertVC.alertActionStackView.axis = .vertical
        alertVC.alertActionStackView.spacing = 0
        alertVC.alertActionStackViewHeightConstraint.constant = 100
        alertVC.modalPresentationStyle = .overFullScreen
        present(alertVC, animated: true, completion: nil)
    }
    
    func showRichError(error: RichError) {
        switch error.level {
        case .warning:
            showWarning(withMessage: error.message)
            
        case .error:
            showError(withMessage: error.message, error: error.internalError)
        }
    }
    
    func showNoConnectionNotification() {
        FTIndicator.showNotification(with: #imageLiteral(resourceName: "error"), title: String.adamantLocalized.alert.noInternetNotificationTitle, message: String.adamantLocalized.alert.noInternetNotificationBoby, autoDismiss: false, tapHandler: nil, completion: nil)
    }
    
    func dissmisNoConnectionNotification() {
        FTIndicator.dismissNotification()
    }
}

// MARK: - Notifications
extension AdamantDialogService {
    func showNotification(title: String?, message: String?, image: UIImage?, tapHandler: (() -> Void)?) {
        if let image = image {
            FTIndicator.showNotification(with: image, title: title, message: message, tapHandler: tapHandler)
        } else {
            FTIndicator.showNotification(withTitle: title, message: message, tapHandler: tapHandler)
        }
    }
    
    func dismissNotification() {
        FTIndicator.dismissNotification()
    }
}

// MAKR: - Activity controllers
extension AdamantDialogService {
    func presentShareAlertFor(adm: String, types: [AddressChatShareType], animated: Bool, from: UIView?, completion: (() -> Void)?, didSelect: ((AddressChatShareType) -> Void)?) {
        let alert = UIAlertController(title: adm, message: nil, preferredStyle: .actionSheet)
        
        for type in types {
            alert.addAction(UIAlertAction(title: type.localized + adm, style: .default) { _ in
                didSelect?(type)
            })
        }
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
        
        if let sourceView = from {
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
            alert.popoverPresentationController?.canOverlapSourceViewRect = false
        }
        
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: animated, completion: completion)
    }
    
    func presentShareAlertFor(string: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIView?, completion: (() -> Void)?) {
        let source: ViewSource?
        if let from = from {
            source = .view(from)
        } else {
            source = nil
        }
        
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
        let source: ViewSource?
        if let from = from {
            source = .view(from)
        } else {
            source = nil
        }
        
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
    }
    
    private func createShareAlertFor(stringForPasteboard: String, stringForShare: String, stringForQR: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: ViewSource?, completion: (() -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
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
                        break
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
                        self?.showError(withMessage: error.localizedDescription, error: error)
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
        
        return alert
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showError(withMessage: error.localizedDescription)
        } else {
            showSuccess(withMessage: String.adamantLocalized.alert.done)
        }
    }
    
    func presentGoToSettingsAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
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

// MARK: - Alerts
fileprivate extension UIAlertAction.Style {
    func asPMAlertAction() -> PMAlertActionStyle {
        switch self {
        case .cancel:
            return .cancel
            
        case .default,
             .destructive:
            return .default
        @unknown default:
            return .default
        }
    }
}

fileprivate extension AdamantAlertStyle {
    func asUIAlertControllerStyle() -> UIAlertController.Style {
        switch self {
        case .alert,
             .richNotification:
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
    
    func asPMAlertAction() -> PMAlertAction {
        let handler = self.handler
        return PMAlertAction(title: self.title, style: self.style.asPMAlertAction(), action: handler)
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
            
        case .richNotification:
            if let actions = actions {
                let pmActions: [PMAlertAction] = actions.map { $0.asPMAlertAction() }
                showAlert(title: title ?? "", message: message ?? "", actions: pmActions)
            } else {
                showAlert(title: title ?? "", message: message ?? "", actions: nil)
            }
        }
    }
    
    func showAlert(title: String?, message: String?, style: UIAlertController.Style, actions: [UIAlertAction]?, from: Any?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        
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
    
    func showAlert(title: String, message: String, actions: [PMAlertAction]?) {
        let alertVC = PMAlertController(title: title, description: message, image: nil, style: .alert)
        
        alertVC.gravityDismissAnimation = false
        alertVC.alertTitle.textColor = UIColor.adamant.primary
        alertVC.alertDescription.textColor = UIColor.adamant.secondary
        alertVC.alertTitle.font = UIFont.systemFont(ofSize: 20)
        alertVC.alertDescription.font = UIFont.systemFont(ofSize: 14, weight: .light)
        
        if let actions = actions {
            for action in actions {
                action.titleLabel?.font = UIFont.systemFont(ofSize: 16)
                action.setTitleColor(UIColor.adamant.secondary, for: .normal)
                alertVC.addAction(action)
            }
            
            let cancelAction = PMAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel)
            cancelAction.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            cancelAction.setTitleColor(UIColor.white, for: .normal)
            cancelAction.backgroundColor = UIColor.adamant.secondary

            alertVC.addAction(cancelAction)
            
            alertVC.alertActionStackViewHeightConstraint.constant = CGFloat((actions.count + 1) * 50) + alertVC.alertActionStackView.spacing * CGFloat(actions.count)
        } else {
            let okBtn = PMAlertAction(title: String.adamantLocalized.alert.ok, style: .default)
            
            okBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            okBtn.setTitleColor(UIColor.white, for: .normal)
            okBtn.backgroundColor = UIColor.adamant.secondary
            alertVC.addAction(okBtn)
            
            alertVC.alertActionStackViewHeightConstraint.constant = 50
        }
        alertVC.modalPresentationStyle = .overFullScreen
        
        DispatchQueue.onMainAsync { [weak self] in
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
}

private class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
