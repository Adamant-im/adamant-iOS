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
import CommonKit

// MARK: - Localization
extension String.adamant {
    enum login {
        static var loggingInProgressMessage: String {
            String.localized("LoginScene.LoggingInProgress", comment: "Login: notify user that we are trying to log in")
        }
        static var loginIntoPrevAccount: String {
            String.localized("LoginScene.LoginIntoAdamant", comment: "Login: Login into previous account with biometry or pincode")
        }
        static var wrongQrError: String {
            String.localized("LoginScene.Error.WrongQr", comment: "Login: Notify user that scanned QR doesn't contains a passphrase.")
        }
        static var noQrError: String {
            String.localized("LoginScene.Error.NoQrOnPhoto", comment: "Login: Notify user that picked photo doesn't contains a valid qr code with passphrase")
        }
        static var noNetworkError: String {
            String.localized("LoginScene.Error.NoInternet", comment: "Login: No network error.")
        }
        static var cameraNotAuthorized: String {
            String.localized("LoginScene.Error.AuthorizeCamera", comment: "Login: Notify user, that he disabled camera in settings, and need to authorize application.")
        }
        static var cameraNotSupported: String {
            String.localized("LoginScene.Error.QrNotSupported", comment: "Login: Notify user that device not supported by QR reader")
        }
        static var photolibraryNotAuthorized: String {
            String.localized("LoginScene.Error.AuthorizePhotolibrary", comment: "Login: User disabled access to photolibrary, he can authorize application in settings")
        }
        static var emptyPassphraseAlert: String {
            String.localized("LoginScene.Error.NoPassphrase", comment: "Login: notify user that he is trying to login without a passphrase")
        }
    }
}

// MARK: - ViewController
final class LoginViewController: FormViewController {
    
    // MARK: Rows & Sections
    
    enum Sections {
        case login
        case newAccount
        
        var localized: String {
            switch self {
            case .login:
                return .localized("LoginScene.Section.Login", comment: "Login: login with existing passphrase section")
                
            case .newAccount:
                return .localized("LoginScene.Section.NewAccount", comment: "Login: Create new account section")
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
        case coinsNodes
        
        var localized: String {
            switch self {
            case .passphrase:
                return .localized("LoginScene.Row.Passphrase.Placeholder", comment: "Login: Passphrase placeholder")
                
            case .loginButton:
                return .localized("LoginScene.Row.Login", comment: "Login: Login button")
                
            case .loginWithQr:
                return .localized("LoginScene.Row.Qr", comment: "Login: Login with QR button.")
                
            case .loginWithPin:
                return .localized("LoginScene.Row.Pincode", comment: "Login: Login with pincode button")
                
            case .saveYourPassphraseAlert:
                return .localized("LoginScene.Row.SavePassphraseAlert", comment: "Login: security alert, notify user that he must save his new passphrase. Markdown supported, center aligned.")
                
            case .generateNewPassphraseButton:
                return .localized("LoginScene.Row.Generate", comment: "Login: generate new passphrase button")
                
            case .tapToSaveHint:
                return .localized("LoginScene.Row.TapToSave", comment: "Login: a small hint for a user, that he can tap on passphrase to save it")
                
            case .newPassphrase:
                return ""
                
            case .nodes:
                return .adamant.nodesList.nodesListButton
                
            case .coinsNodes:
                return .adamant.coinsNodesList.title
            }
        }
        
        var tag: String {
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
            case .coinsNodes: return "coinsNodes"
            }
        }
    }
    
    // MARK: Dependencies
    
    let accountService: AccountService
    let adamantCore: AdamantCore
    let localAuth: LocalAuthentication
    let screensFactory: ScreensFactory
    let apiService: AdamantApiServiceProtocol
    let dialogService: DialogService
    
    // MARK: Properties
    private var hideNewPassphrase: Bool = true
    private var firstTimeActive: Bool = true
    internal var hidingImagePicker: Bool = false
    
    private lazy var versionFooterView = VersionFooterView()
    
    /// On launch, request user biometry (TouchID/FaceID) if has an account with biometry active
    var requestBiometryOnFirstTimeActive: Bool = true
    
    // MARK: Init
    
    init(
        accountService: AccountService,
        adamantCore: AdamantCore,
        dialogService: DialogService,
        localAuth: LocalAuthentication,
        screensFactory: ScreensFactory,
        apiService: AdamantApiServiceProtocol
    ) {
        self.accountService = accountService
        self.adamantCore = adamantCore
        self.dialogService = dialogService
        self.localAuth = localAuth
        self.screensFactory = screensFactory
        self.apiService = apiService
        
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationOptions = RowNavigationOptions.Disabled
        tableView.tableFooterView = versionFooterView
        setVersion()
        
        // MARK: Header & Footer
        if let header = UINib(nibName: "LogoFullHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
            tableView.tableHeaderView = header
            
            if let label = header.viewWithTag(888) as? UILabel {
                label.text = String.adamant.shared.productName
                label.textColor = UIColor.adamant.primary
            }
        }
        
        // MARK: Login section
        form +++ Section(Sections.login.localized) {
            $0.tag = Sections.login.tag
            
            $0.footer = { [weak self] in
                var footer = HeaderFooterView<UIView>(.callback {
                    let view = ButtonsStripeView.adamantConfigured()
                    
                    var stripe: [StripeButtonType] = [.qrCameraReader, .qrPhotoReader]
                    
                    if let accountService = self?.accountService,
                       accountService.hasStayInAccount {
                        stripe.append(.pinpad)
                        if accountService.useBiometry,
                           let button = self?.localAuth.biometryType.stripeButtonType {
                            stripe.append(button)
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
        <<< PasswordRow {
            $0.tag = Rows.passphrase.tag
            $0.placeholder = Rows.passphrase.localized
            $0.placeholderColor = UIColor.adamant.secondary
            $0.cell.textField.enablePasswordToggle()
            $0.keyboardReturnType = KeyboardReturnTypeConfiguration(nextKeyboardType: .go, defaultKeyboardType: .go)
            }
            
        // Login with passphrase row
        <<< ButtonRow {
            $0.tag = Rows.loginButton.tag
            $0.title = Rows.loginButton.localized
            $0.disabled = Condition.function([Rows.passphrase.tag], { form -> Bool in
                guard let row: PasswordRow = form.rowBy(tag: Rows.passphrase.tag), row.value != nil else {
                    return true
                }
                return false
            })
        }.onCellSelection { [weak self] (_, row) in
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
        <<< TextAreaRow {
            $0.tag = Rows.saveYourPassphraseAlert.tag
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
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
        <<< PassphraseRow {
            $0.tag = Rows.newPassphrase.tag
            $0.cell.tip = Rows.tapToSaveHint.localized
            $0.cell.height = {96.0}
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                return self?.hideNewPassphrase ?? true
            })
        }.cellUpdate({ (cell, _) in
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
        
        <<< ButtonRow {
            $0.tag = Rows.generateNewPassphraseButton.tag
            $0.title = Rows.generateNewPassphraseButton.localized
        }.onCellSelection { [weak self] (_, _) in
            self?.generateNewPassphrase()
        }
        
        // MARK: Nodes list settings
        form +++ Section()
        <<< ButtonRow {
            $0.title = Rows.nodes.localized
            $0.tag = Rows.nodes.tag
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.textLabel?.textColor = UIColor.adamant.primary
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeNodesList()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .overFullScreen
            present(nav, animated: true, completion: nil)
        }
        
        // MARK: Coins nodes list settings
        <<< ButtonRow {
            $0.title = Rows.coinsNodes.localized
            $0.tag = Rows.coinsNodes.tag
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.textLabel?.textColor = UIColor.adamant.primary
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeCoinsNodesList(context: .login)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .overFullScreen
            present(nav, animated: true, completion: nil)
        }
        
        // MARK: tableView position tuning
        if let row: PasswordRow = form.rowBy(tag: Rows.passphrase.tag) {
            NotificationCenter.default.addObserver(
                forName: UITextField.textDidBeginEditingNotification,
                object: row.cell.textField,
                queue: OperationQueue.main
            ) { [weak self] _ in
                MainActor.assumeIsolatedSafe {
                    guard let tableView = self?.tableView, let indexPath = self?.form.rowBy(tag: Rows.loginButton.tag)?.indexPath else {
                        return
                    }
                    
                    tableView.scrollToRow(at: indexPath, at: .none, animated: true)
                }
            }
        }
        
        // MARK: Requesting biometry onActive
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            MainActor.assumeIsolatedSafe {
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
        }
        
        setColors()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        versionFooterView.sizeToFit()
    }
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
    
    private func setVersion() {
        versionFooterView.model = .init(
            version: AdamantUtilities.applicationVersion,
            commit: nil
        )
    }
}

// MARK: - Login functions
extension LoginViewController {
    func loginWith(passphrase: String) {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
            dialogService.showWarning(withMessage: AccountServiceError.invalidPassphrase.localized)
            return
        }
        
        dialogService.showProgress(withMessage: String.adamant.login.loggingInProgressMessage, userInteractionEnable: false)
        
        Task {
            let result = await apiService.getAccount(byPassphrase: passphrase)
            
            switch result {
            case .success:
                loginIntoExistingAccount(passphrase: passphrase)
                
            case .failure(let error):
                dialogService.showRichError(error: error)
            }
        }
    }
    
    func generateNewPassphrase() {
        let passphrase = (try? Mnemonic.generate().joined(separator: " ")) ?? .empty
        
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
    
    @MainActor
    private func loginIntoExistingAccount(passphrase: String) {
        Task {
            do {
                let result = try await accountService.loginWith(passphrase: passphrase)
                
                if let nav = navigationController {
                    nav.popViewController(animated: true)
                } else {
                    dismiss(animated: true, completion: nil)
                }

                dialogService.dismissProgress()
                
                if case .success(_, let alert) = result,
                   let alert = alert {
                    dialogService.showAlert(title: alert.title, message: alert.message, style: UIAlertController.Style.alert, actions: nil, from: nil)
                }
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
}

// MARK: - Button stripe
extension LoginViewController: ButtonsStripeViewDelegate {
    func buttonsStripe(didTapButton button: StripeButtonType) {
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
