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
import Haring

class NotificationsViewController: FormViewController {

    // MARK: Sections & Rows
    enum Sections {
        case notifications
        case aboutNotificationTypes
        
        var tag: String {
            switch self {
            case .notifications: return "st"
            case .aboutNotificationTypes: return "ans"
            }
        }
        
        var localized: String {
            switch self {
            case .notifications: return NSLocalizedString("SecurityPage.Section.NotificationsType", comment: "Security: Selected notifications types")
            case .aboutNotificationTypes: return NSLocalizedString("SecurityPage.Section.AboutNotificationTypes", comment: "Security: About Notification types")
            }
        }
    }
    
    enum Rows {
        case notificationsMode
        case description, github
        
        var tag: String {
            switch self {
            case .notificationsMode: return "rn"
            case .description: return "rd"
            case .github: return "git"
            }
        }
        
        var localized: String {
            switch self {
            case .notificationsMode: return NSLocalizedString("SecurityPage.Row.Notifications", comment: "Security: Show notifications")
            case .description: return NSLocalizedString("SecurityPage.Row.Notifications.ModesDescription", comment: "Security: Notification modes description. Markdown supported.")
            case .github: return NSLocalizedString("SecurityPage.Row.VisitGithub", comment: "Security: Visit Github")
            }
        }
    }
    
    // MARK: - Dependencies
    
    var dialogService: DialogService!
    var notificationsService: NotificationsService!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
        
        navigationItem.title = String.adamantLocalized.security.title
        navigationOptions = .Disabled
        
        // MARK: Notifications
        // Type
        let nType = ActionSheetRow<NotificationsMode>() {
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
        }
        
        notificationsSection.append(nType)
        form.append(notificationsSection)
        
        
        // MARK: ANS Description
        // Description
        let descriptionRow = TextAreaRow() {
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
            $0.tag = Rows.description.tag
        }.cellUpdate { (cell, _) in
            cell.textView.isSelectable = false
            cell.textView.isEditable = false
            
            let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
            parser.color = UIColor.adamant.primary
            parser.link.color = UIColor.adamant.secondary
            cell.textView.attributedText = parser.parse(Rows.description.localized)
        }
        
        // Github readme
        let githubRow = LabelRow() {
            $0.tag = Rows.github.tag
            $0.title = Rows.github.localized
            $0.cell.imageView?.image = #imageLiteral(resourceName: "row_github")
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, row) in
            guard let url = URL(string: AdamantResources.ansReadmeUrl) else {
                fatalError("Failed to build ANS URL")
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
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
    }
    
    func setNotificationMode(_ mode: NotificationsMode) {
        guard mode != notificationsService.notificationsMode else {
            return
        }
        
        notificationsService.setNotificationsMode(mode) { [weak self] result in
            switch result {
            case .success:
                return
                
            case .failure(let error):
                if let row: SwitchRow = self?.form.rowBy(tag: Rows.notificationsMode.tag) {
                    row.value = false
                    row.updateCell()
                }
                
                switch error {
                case .notEnoughMoney:
                    self?.dialogService.showRichError(error: error)
                    
                case .denied:
                    self?.presentNotificationsDeniedError()
                }
            }
        }
    }
    
    private func presentNotificationsDeniedError() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: String.adamantLocalized.notifications.notificationsDisabled, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default) { _ in
                DispatchQueue.main.async {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            })
            
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
            
            self?.present(alert, animated: true, completion: nil)
        }
    }
}
