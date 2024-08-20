//
//  NotificationsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import SafariServices
import MarkdownKit
import ProcedureKit
import CommonKit

final class NotificationsViewController: FormViewController {

    // MARK: Sections & Rows
    enum Sections {
        case notifications
        case aboutNotificationTypes
        case messages
        case settings
        
        var tag: String {
            switch self {
            case .notifications: return "st"
            case .aboutNotificationTypes: return "ans"
            case .messages: return "ms"
            case .settings: return "settings"
            }
        }
        
        var localized: String {
            switch self {
            case .notifications: return .localized("SecurityPage.Section.NotificationsType", comment: "Security: Selected notifications types")
            case .aboutNotificationTypes: return .localized("SecurityPage.Section.AboutNotificationTypes", comment: "Security: About Notification types")
            case .messages: return .localized("SecurityPage.Section.Messages", comment: "Security: Messages Notification sound")
            case .settings: return .localized("SecurityPage.Section.Settings", comment: "Security: Settings Notification")
            }
        }
    }
    
    enum Rows {
        case notificationsMode
        case description, github
        case systemSettings
        case sound
        
        var tag: String {
            switch self {
            case .notificationsMode: return "rn"
            case .description: return "rd"
            case .github: return "git"
            case .systemSettings: return "ss"
            case .sound: return "sd"
            }
        }
        
        var localized: String {
            switch self {
            case .notificationsMode: return .localized("SecurityPage.Row.Notifications", comment: "Security: Show notifications")
            case .description: return .localized("SecurityPage.Row.Notifications.ModesDescription", comment: "Security: Notification modes description. Markdown supported.")
            case .github: return .localized("SecurityPage.Row.VisitGithub", comment: "Security: Visit Github")
            case .systemSettings: return .localized("Notifications.Settings.System", comment: "Notifications: Open system Settings")
            case .sound: return .localized("Notifications.Sound.Name", comment: "Notifications: Select Sound")
            }
        }
    }
    
    // MARK: - Dependencies
    
    var dialogService: DialogService!
    var notificationsService: NotificationsService!
    
    private lazy var markdownParser: MarkdownParser = {
        let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize), color: UIColor.adamant.textColor)
        parser.link.color = UIColor.adamant.secondary
        return parser
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = String.adamant.security.title
        navigationOptions = .Disabled
        
        // MARK: Notifications
        // Type
        let nType = ActionSheetRow<NotificationsMode> {
            $0.tag = Rows.notificationsMode.tag
            $0.title = Rows.notificationsMode.localized
            $0.selectorTitle = Rows.notificationsMode.localized
            $0.options = [.disabled, .backgroundFetch, .push]
        }.cellUpdate { [weak self] cell, row in
            cell.accessoryType = .disclosureIndicator
            
            guard let notificationsMode = self?.notificationsService.notificationsMode else { return }
            row.value = notificationsMode
        }.onChange { [weak self] row in
            let mode = row.value ?? NotificationsMode.disabled
            self?.setNotificationMode(mode, completion: row.updateCell)
            row.updateCell()
        }
        
        // Section
        let notificationsSection = Section(Sections.notifications.localized) {
            $0.tag = Sections.notifications.tag
        }
        
        notificationsSection.append(nType)
        form.append(notificationsSection)
        
        // MARK: Messages
        // Sound
        let soundRow = LabelRow {
            $0.tag = Rows.sound.tag
            $0.title = Rows.sound.localized
            $0.value = notificationsService.notificationsSound.localized
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] _, row in
            guard let self = self else { return }
            row.deselect()
            let soundsVC = NotificationSoundsViewController(notificationsService: notificationsService, target: .baseMessage)
//            soundsVC.notificationsService = self.notificationsService
            let navigationController = UINavigationController(rootViewController: soundsVC)
            self.present(navigationController, animated: true)
        }
        
        // Section
        let messagesSection = Section(Sections.messages.localized) {
            $0.tag = Sections.messages.tag
        }
        
        messagesSection.append(soundRow)
        form.append(messagesSection)
        
        // MARK: Settings
        // System Settings
        let settingsRow = LabelRow {
            $0.tag = Rows.systemSettings.tag
            $0.title = Rows.systemSettings.localized
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { _, row in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            row.deselect()
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        // Section
        let settingsSection = Section(Sections.settings.localized) {
            $0.tag = Sections.settings.tag
        }
        
        settingsSection.append(settingsRow)
        form.append(settingsSection)
        
        // MARK: ANS Description
        // Description
        let descriptionRow = TextAreaRow {
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
            $0.tag = Rows.description.tag
        }.cellUpdate { [weak self] (cell, _) in
            cell.textView.isSelectable = false
            cell.textView.isEditable = false
            if let parser = self?.markdownParser {
                cell.textView.attributedText = parser.parse(Rows.description.localized)
            } else {
                cell.textView.text = Rows.description.localized
            }
        }
        
        // Github readme
        let githubRow = LabelRow {
            $0.tag = Rows.github.tag
            $0.title = Rows.github.localized
            $0.cell.imageView?.image = .asset(named: "row_github")
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
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
        }
        
        ansSection.append(contentsOf: [descriptionRow, githubRow])
        form.append(ansSection)
        
        // MARK: Notifications
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
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantNotificationService.notificationsSoundChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let row: LabelRow = self?.form.rowBy(tag: Rows.sound.tag) else {
                return
            }
            
            row.value = self?.notificationsService.notificationsSound.localized
            row.updateCell()
        }
        setColors()
    }
    
    // MARK: - Other
    
    func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
    
    func setNotificationMode(_ mode: NotificationsMode, completion: @escaping () -> Void) {
        guard mode != notificationsService.notificationsMode else {
            return
        }

        notificationsService.setNotificationsMode(mode) { [weak self] result in
            DispatchQueue.onMainAsync {
                defer { completion() }
                
                switch result {
                case .success:
                    return
                case .failure(let error):
                    switch error {
                    case .notEnoughMoney, .notStayedLoggedIn:
                        self?.dialogService.showRichError(error: error)
                    case .denied:
                        self?.presentNotificationsDeniedError()
                    }
                }
            }
        }
    }
    
    private func presentNotificationsDeniedError() {
        let alert = UIAlertController(
            title: nil,
            message: NotificationStrings.notificationsDisabled,
            preferredStyleSafe: .alert,
            source: nil
        )
        
        alert.addAction(UIAlertAction(title: String.adamant.alert.settings, style: .default) { _ in
            DispatchQueue.main.async {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: String.adamant.alert.cancel, style: .cancel, handler: nil))
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
}
