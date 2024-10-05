//
//  DialogService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension String.adamant.alert {
    static var copyToPasteboard: String {
        String.localized("Shared.CopyToPasteboard", comment: "Shared alert 'Copy' button. Used anywhere. Used for copy-paste info.")
    }
    static var share: String {
        String.localized("Shared.Share", comment: "Shared alert 'Share' button. Used anywhere for presenting standart iOS 'Share' menu.")
    }
    static var generateQr: String {
        String.localized("Shared.GenerateQRCode", comment: "Shared alert 'Generate QR' button. Used to generate QR codes with addresses and passphrases. Used with sharing and saving, anywhere.")
    }
    static var saveToPhotolibrary: String {
        String.localized("Shared.SaveToPhotolibrary", comment: "Shared alert 'Save to Photos'. Used with saving images to photolibrary")
    }
    
    static var renameContact: String {
        String.localized("Shared.RenameContact", comment: "Partner screen 'Rename contact'")
    }
    
    static var renameContactInitial: String {
        String.localized("Shared.RenameContactInitial", comment: "Partner screen 'Give contact a name' at first")
	}

    static var sendTokens: String {
        String.localized("Shared.SendTokens", comment: "Shared alert 'Send tokens'")
    }
    static var uploadFile: String {
        String.localized("Shared.UploadFile", comment: "Shared alert 'Upload File'")
    }
    static var uploadMedia: String {
        String.localized("Shared.UploadMedia", comment: "Shared alert 'Upload Media'")
    }
    static var openInExplorer: String {
        String.localized("TransactionDetailsScene.Row.Explorer", comment: "Transaction details: 'Open transaction in explorer' row.")
    }
}

enum AddressChatShareType {
     case chat
     case send

     var localized: String {
         switch self {
         case .chat:
             return .localized("Shared.ChatWith", comment: "Shared alert 'Chat With' button. Used to chat with recipient")
         case .send:
             return .localized("Shared.SendAdmTo", comment: "Shared alert 'Send ADM To' button. Used to send ADM to recipient")
         }
     }
 }

enum ShareType {
    case copyToPasteboard
    case share
    case generateQr(encodedContent: String?, sharingTip: String?, withLogo: Bool)
    case openInExplorer(url: URL)
    case saveToPhotolibrary(image: UIImage)
    case partnerQR
    case sendTokens
    case uploadMedia
    case uploadFile
    
    var localized: String {
        switch self {
        case .copyToPasteboard:
            return String.adamant.alert.copyToPasteboard
            
        case .share:
            return String.adamant.alert.share
            
        case .generateQr, .partnerQR:
            return String.adamant.alert.generateQr
            
        case .openInExplorer:
            return String.adamant.alert.openInExplorer
            
        case .saveToPhotolibrary:
            return String.adamant.alert.saveToPhotolibrary
        
        case .sendTokens:
            return String.adamant.alert.sendTokens
        
        case .uploadMedia:
            return String.adamant.alert.uploadMedia
            
        case .uploadFile:
            return String.adamant.alert.uploadFile
        }
    }
}

enum ShareContentType {
    case passphrase
    case address
    
    var excludedActivityTypes: [UIActivity.ActivityType]? {
        switch self {
        case .passphrase:
            var types: [UIActivity.ActivityType] = [.postToFacebook,
                                                    .postToTwitter,
                                                    .postToWeibo,
                                                    .message,
                                                    .mail,
                                                    .assignToContact,
                                                    .saveToCameraRoll,
                                                    .addToReadingList,
                                                    .postToFlickr,
                                                    .postToVimeo,
                                                    .postToTencentWeibo,
                                                    .airDrop,
                                                    .openInIBooks]
            
            types.append(.markupAsPDF)
            return types
            
        case .address:
            return [.assignToContact,
                    .addToReadingList,
                    .openInIBooks]
        }
    }
}

enum ErrorLevel {
    case warning
    case error
    case internalError
}

protocol RichError: LocalizedError {
    var message: String { get }
    var internalError: Error? { get }
    var level: ErrorLevel { get }
}

extension RichError {
    var errorDescription: String? {
        message
    }
}

enum AdamantAlertStyle {
    case alert, actionSheet
}

struct AdamantAlertAction {
    let title: String
    let style: UIAlertAction.Style
    let handler: (() -> Void)?
}

@MainActor
protocol DialogService: AnyObject {
    func setup(window: UIWindow)
    
    func getTopmostViewController() -> UIViewController?
    
    /// Present view controller modally
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
    
    // MARK: - Toast messages
    /// Show pop-up message
    func showToastMessage(_ message: String)
    func dismissToast()
    
    // MARK: - Indicators
    func showProgress(withMessage: String?, userInteractionEnable: Bool)
    func dismissProgress()
    func showSuccess(withMessage: String?)
    func showWarning(withMessage: String)
    func showError(withMessage: String, supportEmail: Bool, error: Error?)
    func showRichError(error: RichError)
    func showRichError(error: Error)
    func showNoConnectionNotification()
    func dissmisNoConnectionNotification()
    
    // MARK: - Notifications
    func showNotification(title: String?, message: String?, image: UIImage?, tapHandler: (() -> Void)?)
    func dismissNotification()
    
    // MARK: - ActivityControllers
    func presentShareAlertFor(adm: String, name: String, types: [AddressChatShareType], animated: Bool, from: UIView?, completion: (() -> Void)?, didSelect: ((AddressChatShareType) -> Void)?)
    func presentShareAlertFor(string: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIView?, completion: (() -> Void)?)
    func presentShareAlertFor(stringForPasteboard: String, stringForShare: String, stringForQR: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIView?, completion: (() -> Void)?)
    func presentShareAlertFor(string: String, types: [ShareType], excludedActivityTypes: [UIActivity.ActivityType]?, animated: Bool, from: UIBarButtonItem?, completion: (() -> Void)?)
    func presentShareAlertFor(
        string: String,
        types: [ShareType],
        excludedActivityTypes: [UIActivity.ActivityType]?,
        animated: Bool,
        from: UIBarButtonItem?,
        completion: (() -> Void)?,
        didSelect: ((ShareType) -> Void)?
    )
    
    func presentGoToSettingsAlert(title: String?, message: String?)
    
    func presentDummyAlert(
        for adm: String,
        from: UIView?,
        canSend: Bool,
        sendCompletion: ((UIAlertAction) -> Void)?
    )
    
    func presentDummyChatAlert(
        for adm: String,
        from: UIView?,
        canSend: Bool,
        sendCompletion: ((UIAlertAction) -> Void)?
    )
    
    func presentDummyAlert(
        for adm: String,
        from: UIView?,
        canSend: Bool,
        message: String,
        sendCompletion: ((UIAlertAction) -> Void)?
    )
    
    // MARK: - Alerts
    func showAlert(title: String?, message: String?, style: UIAlertController.Style, actions: [UIAlertAction]?, from: UIAlertController.SourceView?)
    func showAlert(title: String?, message: String?, style: AdamantAlertStyle, actions: [AdamantAlertAction]?, from: UIAlertController.SourceView?)
    
    func selectAllTextFields(in alert: UIAlertController)
}
