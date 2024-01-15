//
//  SecurityViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Eureka
import SafariServices
import MarkdownKit
import CommonKit

// MARK: - Localization
extension String.adamant {
    enum security {
        static var title: String {
            String.localized("SecurityPage.Title", comment: "Security: scene title")
        }
        
        static var stayInTurnOff: String {
            String.localized("SecurityPage.DoNotStayLoggedIn", comment: "Security: turn off 'Stay Logged In' confirmation")
        }
        static var biometryOnReason: String {
            String.localized("SecurityPage.UseBiometry", comment: "Security: Authorization reason for turning biometry on")
        }
        static var biometryOffReason: String {
            String.localized("SecurityPage.DoNotUseBiometry", comment: "Security: Authorization reason for turning biometry off")
        }
    }
}

// Eureka uses CustomStringConvertible to represen enums as strings
extension NotificationsMode: CustomStringConvertible {
    var description: String {
        return localized
    }
}

// MARK: - SecurityViewController
final class SecurityViewController: FormViewController {
    
    enum PinpadRequest {
        case createPin
        case reenterPin(pin: String)
        case turnOffPin
        case turnOnBiometry
        case turnOffBiometry
    }
    
    // MARK: - Section & Rows
    
    enum Sections {
        case security
        case notifications
        case aboutNotificationTypes
        
        var tag: String {
            switch self {
            case .security: return "ss"
            case .notifications: return "st"
            case .aboutNotificationTypes: return "ans"
            }
        }
        
        var localized: String {
            switch self {
            case .security: return .localized("SecurityPage.Section.Security", comment: "Security: Security section")
            case .notifications: return .localized("SecurityPage.Section.NotificationsType", comment: "Security: Selected notifications types")
            case .aboutNotificationTypes: return .localized("SecurityPage.Section.AboutNotificationTypes", comment: "Security: About Notification types")
            }
        }
    }
    
    enum Rows {
        case generateQr, stayIn, biometry
        case notificationsMode
        case description, github
        
        var tag: String {
            switch self {
            case .generateQr: return "qr"
            case .stayIn: return "rs"
            case .biometry: return "rb"
            case .notificationsMode: return "rn"
            case .description: return "rd"
            case .github: return "git"
            }
        }
        
        var localized: String {
            switch self {
            case .generateQr: return .localized("SecurityPage.Row.GenerateQr", comment: "Security: Generate QR with passphrase row")
            case .stayIn: return .localized("SecurityPage.Row.StayLoggedIn", comment: "Security: Stay logged option")
            case .biometry: return "" // localAuth.biometryType.localized
            case .notificationsMode: return .localized("SecurityPage.Row.Notifications", comment: "Security: Show notifications")
            case .description: return .localized("SecurityPage.Row.Notifications.ModesDescription", comment: "Security: Notification modes description. Markdown supported.")
            case .github: return .localized("SecurityPage.Row.VisitGithub", comment: "Security: Visit Github")
            }
        }
    }
    
    // MARK: - Dependencies
    
    var accountService: AccountService!
    var dialogService: DialogService!
    var notificationsService: NotificationsService!
    var localAuth: LocalAuthentication!
    var screensFactory: ScreensFactory!
    
    // MARK: - Properties
    var showLoggedInOptions: Bool {
        return accountService.hasStayInAccount
    }
    
    var showBiometryOptions: Bool {
        switch localAuth.biometryType {
        case .none:
            return false
            
        case .touchID, .faceID:
            return showLoggedInOptions
        }
    }
    
    var pinpadRequest: SecurityViewController.PinpadRequest?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = String.adamant.security.title
        navigationOptions = .Disabled
        
        // MARK: StayIn
        // Generate QR
        let qrRow = LabelRow {
            $0.title = Rows.generateQr.localized
            $0.tag = Rows.generateQr.tag
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let vc = self?.screensFactory.makeQRGenerator() else { return }
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        // Stay logged in
        let stayInRow = SwitchRow {
            $0.tag = Rows.stayIn.tag
            $0.title = Rows.stayIn.localized
            $0.value = accountService.hasStayInAccount
        }.onChange { [weak self] row in
            guard let enabled = row.value else {
                return
            }
            
            self?.setStayLoggedIn(enabled: enabled)
        }.cellUpdate({ (cell, _) in
            cell.accessoryType = .disclosureIndicator
        })
        
        // Biometry
        let biometryRow = SwitchRow {
            $0.tag = Rows.biometry.tag
            $0.title = localAuth.biometryType.localized
            $0.value = accountService.useBiometry
            
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                guard let showBiometry = self?.showBiometryOptions else {
                    return true
                }
                
                return !showBiometry
            })
        }.onChange { [weak self] row in
            let value = row.value ?? false
            self?.setBiometry(enabled: value)
        }.cellUpdate({ (cell, _) in
            cell.accessoryType = .disclosureIndicator
        })
        
        let stayInSection = Section(Sections.security.localized) {
            $0.tag = Sections.security.tag
        }
        
        stayInSection.append(contentsOf: [qrRow, stayInRow, biometryRow])
        form.append(stayInSection)
        
        // MARK: Notifications
        // Type
        let nType = ActionSheetRow<NotificationsMode> {
            $0.tag = Rows.notificationsMode.tag
            $0.title = Rows.notificationsMode.localized
            $0.selectorTitle = Rows.notificationsMode.localized
            $0.options = [.disabled, .backgroundFetch, .push]
            $0.value = notificationsService.notificationsMode
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onChange { [weak self] row in
            let mode = row.value ?? NotificationsMode.disabled
            self?.setNotificationMode(mode)
        }
        
        // Section
        let notificationsSection = Section(Sections.notifications.localized) {
            $0.tag = Sections.notifications.tag
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                guard let showNotifications = self?.showLoggedInOptions else {
                    return true
                }
                
                return !showNotifications
            })
        }
        
        notificationsSection.append(nType)
        form.append(notificationsSection)
        
        // MARK: ANS Description
        // Description
        let descriptionRow = TextAreaRow {
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
            $0.tag = Rows.description.tag
        }.cellUpdate { (cell, _) in
            cell.textView.isSelectable = false
            cell.textView.isEditable = false
            
            let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
            cell.textView.attributedText = parser.parse(Rows.description.localized)
        }
        
        // Github readme
        let githubRow = LabelRow {
            $0.tag = Rows.github.tag
            $0.title = Rows.github.localized
            $0.cell.imageView?.image = .asset(named: "row_github")
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate({ (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }).onCellSelection { [weak self] (_, _) in
            guard let url = URL(string: AdamantResources.ansReadmeUrl) else {
                fatalError("Failed to build ANS URL")
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            self?.present(safari, animated: true, completion: nil)
        }
        
        let ansSection = Section(Sections.aboutNotificationTypes.localized) {
            $0.tag = Sections.aboutNotificationTypes.tag
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                guard let showNotifications = self?.showLoggedInOptions else {
                    return true
                }
                
                return !showNotifications
            })
        }
        
        ansSection.append(contentsOf: [descriptionRow, githubRow])
        form.append(ansSection)
        
        // MARK: Notifications
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.reloadForm()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.stayInChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.reloadForm()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantNotificationService.notificationsModeChanged, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let newMode = notification.userInfo?[AdamantUserInfoKey.NotificationsService.newNotificationsMode] as? NotificationsMode else {
                return
            }
            
            guard let row: ActionSheetRow<NotificationsMode> = self?.form.rowBy(tag: Rows.notificationsMode.tag) else {
                return
            }
            
            row.value = newMode
            row.updateCell()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    private func reloadForm() {
        if let row: SwitchRow = form.rowBy(tag: Rows.stayIn.tag) {
            row.value = accountService.hasStayInAccount
        }
        
        if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
            row.value = accountService.hasStayInAccount && accountService.useBiometry
            row.evaluateHidden()
        }
        
        if let section = form.sectionBy(tag: Sections.notifications.tag) {
            section.evaluateHidden()
        }
        
        if let section = form.sectionBy(tag: Sections.aboutNotificationTypes.tag) {
            section.evaluateHidden()
        }
    }
}
