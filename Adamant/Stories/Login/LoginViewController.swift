//
//  LoginViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import MarkdownKit

// MARK: - Localization
extension String.adamantLocalized {
    struct login {
        static let loggingInProgressMessage = NSLocalizedString("LoginScene.LoggingInProgress", comment: "Login: notify user that we are trying to log in")
        
        static let loginIntoPrevAccount = NSLocalizedString("LoginScene.LoginIntoAdamant", comment: "Login: Login into previous account with biometry or pincode")
        
        static let wrongQrError = NSLocalizedString("LoginScene.Error.WrongQr", comment: "Login: Notify user that scanned QR doesn't contains a passphrase.")
        static let noQrError = NSLocalizedString("LoginScene.Error.NoQrOnPhoto", comment: "Login: Notify user that picked photo doesn't contains a valid qr code with passphrase")
        static let noNetworkError = NSLocalizedString("LoginScene.Error.NoInternet", comment: "Login: No network error.")
        
        static let cameraNotAuthorized = NSLocalizedString("LoginScene.Error.AuthorizeCamera", comment: "Login: Notify user, that he disabled camera in settings, and need to authorize application.")
        static let cameraNotSupported = NSLocalizedString("LoginScene.Error.QrNotSupported", comment: "Login: Notify user that device not supported by QR reader")
        
        static let photolibraryNotAuthorized = NSLocalizedString("LoginScene.Error.AuthorizePhotolibrary", comment: "Login: User disabled access to photolibrary, he can authorize application in settings")
        
        static let emptyPassphraseAlert = NSLocalizedString("LoginScene.Error.NoPassphrase", comment: "Login: notify user that he is trying to login without a passphrase")
        
        private init() {}
    }
}


// MARK: - ViewController
class LoginViewController: FormViewController {
    
    // MARK: Rows & Sections
    
    enum Sections {
        case login
        case newAccount
        
        var localized: String {
            switch self {
            case .login:
                return NSLocalizedString("LoginScene.Section.Login", comment: "Login: login with existing passphrase section")
                
            case .newAccount:
                return NSLocalizedString("LoginScene.Section.NewAccount", comment: "Login: Create new account section")
            }
        }
        
        var tag: String {
            switch self {
            case .login: return "loginSection"
            case .newAccount: return "newAccount"
            }
        }
    }
    
    enum Rows {
        case passphrase
        case loginButton
        case loginWithQr
        case loginWithPin
        case newPassphrase
        case saveYourPassphraseAlert
        case tapToSaveHint
        case generateNewPassphraseButton
        case nodes
        
        var localized: String {
            switch self {
            case .passphrase:
                return NSLocalizedString("LoginScene.Row.Passphrase.Placeholder", comment: "Login: Passphrase placeholder")
                
            case .loginButton:
                return NSLocalizedString("LoginScene.Row.Login", comment: "Login: Login button")
                
            case .loginWithQr:
                return NSLocalizedString("LoginScene.Row.Qr", comment: "Login: Login with QR button.")
                
            case .loginWithPin:
                return NSLocalizedString("LoginScene.Row.Pincode", comment: "Login: Login with pincode button")
                
            case .saveYourPassphraseAlert:
                return NSLocalizedString("LoginScene.Row.SavePassphraseAlert", comment: "Login: security alert, notify user that he must save his new passphrase. Markdown supported, center aligned.")
                
            case .generateNewPassphraseButton:
                return NSLocalizedString("LoginScene.Row.Generate", comment: "Login: generate new passphrase button")
                
            case .tapToSaveHint:
                return NSLocalizedString("LoginScene.Row.TapToSave", comment: "Login: a small hint for a user, that he can tap on passphrase to save it")
                
            case .newPassphrase:
                return ""
                
            case .nodes:
                return String.adamantLocalized.nodesList.nodesListButton
            }
        }
        
        var tag:String {
            switch self {
            case .passphrase: return "pass"
            case .loginButton: return "login"
            case .loginWithQr: return "qr"
            case .loginWithPin: return "pin"
            case .newPassphrase: return "newPass"
            case .saveYourPassphraseAlert: return "alert"
            case .generateNewPassphraseButton: return "generate"
            case .tapToSaveHint: return "hint"
            case .nodes: return "nodes"
            }
        }
    }
    
    
    // MARK: Dependencies
    
    var accountService: AccountService!
    var adamantCore: AdamantCore!
    var dialogService: DialogService!
    var localAuth: LocalAuthentication!
    var router: Router!
    var apiService: ApiService!
    
    // MARK: Properties
    private var hideNewPassphrase: Bool = true
    private var firstTimeActive: Bool = true
    internal var hidingImagePicker: Bool = false
    
    
    /// On launch, request user biometry (TouchID/FaceID) if has an account with biometry active
    var requestBiometryOnFirstTimeActive: Bool = true
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationOptions = RowNavigationOptions.Disabled
        
        // MARK: Header & Footer
        if let header = UINib(nibName: "LogoFullHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
            tableView.tableHeaderView = header
            
            if let label = header.viewWithTag(888) as? UILabel {
                label.text = String.adamantLocalized.shared.productName
                label.textColor = UIColor.adamant.primary
            }
        }
        
        if let footer = UINib(nibName: "VersionFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
            if let label = footer.viewWithTag(555) as? UILabel {
                label.text = AdamantUtilities.applicationVersion
                label.textColor = UIColor.adamant.primary
                tableView.tableFooterView = footer
            }
        }
        
        
        // MARK: Login section
        form +++ Section(Sections.login.localized) {
            $0.tag = Sections.login.tag
            
            $0.footer = { [weak self] in
                var footer = HeaderFooterView<UIView>(.callback {
                    let view = ButtonsStripeView.adamantConfigured()
                    
                    var stripe: [StripeButtonType] = [.qrCameraReader, .qrPhotoReader]
                    
                    if let accountService = self?.accountService, accountService.hasStayInAccount {
                        if accountService.useBiometry, let button = self?.localAuth.biometryType.stripeButtonType {
                            stripe.append(button)
                        } else {
                            stripe.append(.pinpad)
                        }
                    }
                    
                    view.stripe = stripe
                    view.delegate = self
                    
                    return view
                })
                
                footer.height = { ButtonsStripeView.adamantDefaultHeight }
                
                return footer
            }()
        }
        
        // Passphrase row
        <<< PasswordRow() {
            $0.tag = Rows.passphrase.tag
            $0.placeholder = Rows.passphrase.localized
            $0.placeholderColor = UIColor.adamant.secondary
            $0.keyboardReturnType = KeyboardReturnTypeConfiguration(nextKeyboardType: .go, defaultKeyboardType: .go)
            }
            
        // Login with passphrase row
        <<< ButtonRow() {
            $0.tag = Rows.loginButton.tag
            $0.title = Rows.loginButton.localized
            $0.disabled = Condition.function([Rows.passphrase.tag], { form -> Bool in
                guard let row: PasswordRow = form.rowBy(tag: Rows.passphrase.tag), row.value != nil else {
                    return true
                }
                return false
            })
        }.onCellSelection { [weak self] (cell, row) in
            guard let row: PasswordRow = self?.form.rowBy(tag: Rows.passphrase.tag), let passphrase = row.value else {
                return
            }
            
            self?.loginWith(passphrase: passphrase)
        }
        
        
        // MARK: New account section
        form +++ Section(Sections.newAccount.localized) {
            $0.tag = Sections.newAccount.tag
        }
        
        // Alert
        <<< TextAreaRow() {
            $0.tag = Rows.saveYourPassphraseAlert.tag
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
            $0.hidden = Condition.function([], { [weak self] form -> Bool in
                return self?.hideNewPassphrase ?? false
            })
        }.cellUpdate { (cell, _) in
            cell.textView.textAlignment = .center
            cell.textView.isSelectable = false
            cell.textView.isEditable = false
            
            let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize), color: UIColor.adamant.primary)
            
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.center
            
            let mutableText = NSMutableAttributedString(attributedString: parser.parse(Rows.saveYourPassphraseAlert.localized))
            mutableText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: mutableText.length))
            
            cell.textView.attributedText = mutableText
        }
        
        // New genegated passphrase
        <<< PassphraseRow() {
            $0.tag = Rows.newPassphrase.tag
            $0.cell.tip = Rows.tapToSaveHint.localized
            $0.cell.height = {96.0}
            $0.hidden = Condition.function([], { [weak self] form -> Bool in
                return self?.hideNewPassphrase ?? true
            })
        }.cellUpdate({ (cell, row) in
            cell.passphraseLabel.font = UIFont.systemFont(ofSize: 19)
            cell.passphraseLabel.textColor = UIColor.adamant.primary
            cell.passphraseLabel.textAlignment = .center
        
            cell.tipLabel.font = UIFont.systemFont(ofSize: 12)
            cell.tipLabel.textColor = UIColor.adamant.secondary
            cell.tipLabel.textAlignment = .center
        }).onCellSelection({ [weak self] (cell, row) in
            guard let passphrase = row.value, let dialogService = self?.dialogService else {
                return
            }
            
            if let indexPath = row.indexPath, let tableView = self?.tableView {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            let encodedPassphrase = AdamantUriTools.encode(request: AdamantUri.passphrase(passphrase: passphrase))
            dialogService.presentShareAlertFor(string: passphrase,
                                               types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedPassphrase, sharingTip: nil, withLogo: false)],
                                               excludedActivityTypes: ShareContentType.passphrase.excludedActivityTypes,
                                               animated: true, from: cell,
                                               completion: nil)
        })
        
        <<< ButtonRow() {
            $0.tag = Rows.generateNewPassphraseButton.tag
            $0.title = Rows.generateNewPassphraseButton.localized
        }.onCellSelection { [weak self] (cell, row) in
            self?.generateNewPassphrase()
        }
        
        // MARK: Nodes list settings
        form +++ Section()
        <<< ButtonRow() {
            $0.title = Rows.nodes.localized
            $0.tag = Rows.nodes.tag
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.textLabel?.textColor = UIColor.adamant.primary
        }.onCellSelection { [weak self] (_, _) in
            guard let vc = self?.router.get(scene: AdamantScene.NodesEditor.nodesList) else {
                return
            }
            
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .overFullScreen
            self?.present(nav, animated: true, completion: nil)
        }
        
        // MARK: tableView position tuning
        if let row: PasswordRow = form.rowBy(tag: Rows.passphrase.tag) {
            NotificationCenter.default.addObserver(forName: UITextField.textDidBeginEditingNotification, object: row.cell.textField, queue: nil) { [weak self] _ in
                guard let tableView = self?.tableView, let indexPath = self?.form.rowBy(tag: Rows.loginButton.tag)?.indexPath else {
                    return
                }
                
                DispatchQueue.main.async {
                    tableView.scrollToRow(at: indexPath, at: .none, animated: true)
                }
            }
        }
        
        // MARK: Requesting biometry onActive
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let vc = self,
                vc.firstTimeActive,
                vc.requestBiometryOnFirstTimeActive,
                vc.accountService.hasStayInAccount,
                vc.accountService.useBiometry else {
                return
            }
            
            vc.loginWithBiometry()
            vc.firstTimeActive = false
        }
        
        updateTheme()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateTheme()
    }
    
    private func updateTheme() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
}


// MARK: - Login functions
extension LoginViewController {
    func loginWith(passphrase: String) {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
            dialogService.showWarning(withMessage: AccountServiceError.invalidPassphrase.localized)
            return
        }
        
        dialogService.showProgress(withMessage: String.adamantLocalized.login.loggingInProgressMessage, userInteractionEnable: false)
        
        apiService.getAccount(byPassphrase: passphrase) { [weak self] result in
            switch result {
            case .success(_):
                self?.loginIntoExistingAccount(passphrase: passphrase)
                
            case .failure(let error):
                self?.dialogService.showRichError(error: error)
            }
        }
    }
    
    func generateNewPassphrase() {
        let passphrase = adamantCore.generateNewPassphrase()
        
        hideNewPassphrase = false
        
        form.rowBy(tag: Rows.saveYourPassphraseAlert.tag)?.evaluateHidden()
        
        if let row: PassphraseRow = form.rowBy(tag: Rows.newPassphrase.tag) {
            row.value = passphrase
            row.updateCell()
            row.evaluateHidden()
        }
        
        if let row = form.rowBy(tag: Rows.generateNewPassphraseButton.tag), let indexPath = row.indexPath {
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        }
    }
    
    private func loginIntoExistingAccount(passphrase: String) {
        accountService.loginWith(passphrase: passphrase, completion: { [weak self] result in
            switch result {
            case .success(_, let alert):
                DispatchQueue.main.async {
                    if let nav = self?.navigationController {
                        nav.popViewController(animated: true)
                    } else {
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
                
                self?.dialogService.dismissProgress()
                
                if let alert = alert {
                    self?.dialogService?.showAlert(title: alert.title, message: alert.message, style: UIAlertController.Style.alert, actions: nil, from: nil)
                }
                
            case .failure(let error):
                self?.dialogService.showRichError(error: error)
            }
        })
    }
}


// MARK: - Button stripe
extension LoginViewController: ButtonsStripeViewDelegate {
    func buttonsStripe(_ stripe: ButtonsStripeView, didTapButton button: StripeButtonType) {
        switch button {
        case .pinpad:
            loginWithPinpad()
            
        case .touchID, .faceID:
            loginWithBiometry()
            
        case .qrCameraReader:
            loginWithQrFromCamera()
            
        case .qrPhotoReader:
            loginWithQrFromLibrary()
        }
    }
}
