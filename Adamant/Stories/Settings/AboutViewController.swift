//
//  AboutViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Eureka
import SafariServices
import MessageUI

// MARK: - Localization
extension String.adamantLocalized {
    struct about {
        static let title = NSLocalizedString("About.Title", comment: "About page: scene title")
        
        private init() { }
    }
}

// MARK: - AboutViewController
class AboutViewController: FormViewController {
    // MARK: Section & Rows
    
    enum Sections {
        case about
        case contactUs
        
        var tag: String {
            switch self {
            case .about: return "about"
            case .contactUs: return "contact"
            }
        }
        
        var localized: String {
            switch self {
            case .about: return NSLocalizedString("About.Section.About", comment: "About scene: 'Read about' section title.")
            case .contactUs: return NSLocalizedString("About.Section.ContactUs", comment: "About scene: 'Contact us' section title.")
            }
        }
    }
    
    enum Rows {
        case website, whitepaper, blog, github, welcomeScreens
        case adm, email, twitter
        
        var tag: String {
            switch self {
            case .website: return "www"
            case .whitepaper: return "whtpaper"
            case .github: return "git"
            case .welcomeScreens: return "welcome"
            case .adm: return "amd"
            case .email: return "email"
            case .blog: return "blog"
            case .twitter: return "twttr"
            }
        }
        
        var localized: String {
            switch self {
            case .website: return NSLocalizedString("About.Row.Website", comment: "About scene: Website row")
            case .whitepaper: return NSLocalizedString("About.Row.Whitepaper", comment: "About scene: The Whitepaper row")
            case .github: return NSLocalizedString("About.Row.GitHub", comment: "About scene: Project's GitHub page row")
            case .adm: return NSLocalizedString("About.Row.Adamant", comment: "About scene: Write to Adamant row")
            case .welcomeScreens: return NSLocalizedString("About.Row.Welcome", comment: "About scene: Show Welcome screens")
            case .email: return NSLocalizedString("About.Row.WriteUs", comment: "About scene: Write us row")
            case .blog: return NSLocalizedString("About.Row.Blog", comment: "About scene: Our blog row")
            case .twitter: return NSLocalizedString("About.Row.Twitter", comment: "About scene: Twitter row")
            }
        }
        
        var localizedUrl: String {
            switch self {
            case .website: return NSLocalizedString("About.Row.Website.Url", comment: "About scene: Website localized url")
            case .whitepaper: return NSLocalizedString("About.Row.Whitepaper.Url", comment: "About scene: The Whitepaper localized url")
            case .github: return NSLocalizedString("About.Row.GitHub.Url", comment: "About scene: Project's GitHub page localized url")
            case .blog: return NSLocalizedString("About.Row.Blog.Url", comment: "About scene: Our blog localized url")
            case .twitter: return NSLocalizedString("About.Row.Twitter.Url", comment: "About scene: Twitter localized url")
                
            // No urls
            case .adm, .email, .welcomeScreens: return ""
            }
        }
        
        var image: UIImage? {
            switch self {
            case .whitepaper: return #imageLiteral(resourceName: "row_whitepapper")
            case .email: return #imageLiteral(resourceName: "row_email")
            case .github: return #imageLiteral(resourceName: "row_github")
            case .blog: return #imageLiteral(resourceName: "row_blog")
            case .adm: return #imageLiteral(resourceName: "row_chat_adamant")
            case .website: return #imageLiteral(resourceName: "row_website")
            case .welcomeScreens: return #imageLiteral(resourceName: "row_logo")
            case .twitter: return #imageLiteral(resourceName: "row_twitter")
            }
        }
    }
    
    // MARK: Dependencies
    var accountService: AccountService!
    var accountsProvider: AccountsProvider!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: Properties
    private var storedIOSSupportMessage: String?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = String.adamantLocalized.about.title
        
        // MARK: Header & Footer
        if let header = UINib(nibName: "LogoFullHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
            tableView.tableHeaderView = header
            
            if let label = header.viewWithTag(888) as? UILabel {
                label.text = String.adamantLocalized.shared.productName
            }
        }
        
        if let footer = UINib(nibName: "VersionFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
            if let label = footer.viewWithTag(555) as? UILabel {
                label.text = AdamantUtilities.applicationVersion
                label.textColor = UIColor.adamant.primary
                tableView.tableFooterView = footer
            }
        }
        
        // MARK: About
        form +++ Section(Sections.about.localized) {
            $0.tag = Sections.about.tag
        }
        
        // Website
        <<< buildUrlRow(title: Rows.website.localized,
                        value: "adamant.im",
                        tag: Rows.website.tag,
                        url: Rows.website.localizedUrl,
                        image: Rows.website.image)
            
        // Whitepaper
        <<< buildUrlRow(title: Rows.whitepaper.localized,
                        value: nil,
                        tag: Rows.whitepaper.tag,
                        url: Rows.whitepaper.localizedUrl,
                        image: Rows.whitepaper.image)
            
        // Blog
        <<< buildUrlRow(title: Rows.blog.localized,
                        value: nil,
                        tag: Rows.blog.tag,
                        url: Rows.blog.localizedUrl,
                        image: Rows.blog.image)
        
        // Twitter
        <<< buildUrlRow(
            title: Rows.twitter.localized,
            value: nil,
            tag: Rows.twitter.tag,
            url: Rows.twitter.localizedUrl,
            image: Rows.twitter.image)
        
        // Github
        <<< buildUrlRow(title: Rows.github.localized,
                        value: nil,
                        tag: Rows.github.tag,
                        url: Rows.github.localizedUrl,
                        image: Rows.github.image)

        // Welcome screens
        <<< LabelRow {
            $0.title = Rows.welcomeScreens.localized
            $0.tag = Rows.welcomeScreens.tag
            $0.cell.imageView?.image = Rows.welcomeScreens.image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let vc = self?.router.get(scene: AdamantScene.Onboard.welcome) else {
                if let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                return
            }
            vc.modalPresentationStyle = .overFullScreen
            self?.present(vc, animated: true, completion: nil)
        }
            
        // MARK: Contact
        +++ Section(Sections.contactUs.localized) {
            $0.tag = Sections.contactUs.tag
        }
            
        // Adamant
        <<< LabelRow {
            $0.title = Rows.adm.localized
            $0.tag = Rows.adm.tag
            $0.cell.imageView?.image = Rows.adm.image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            self?.contactUsAction()
        }
            
        // E-mail
        <<< LabelRow {
            $0.title = Rows.email.localized
            $0.value = AdamantResources.supportEmail
            $0.tag = Rows.email.tag
            $0.cell.imageView?.image = Rows.email.image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            self?.openEmailScreen(
                recipient: AdamantResources.supportEmail,
                subject: "ADAMANT Support",
                body: "\n\n\n" + AdamantUtilities.deviceInfo,
                delegate: self
            )
        }
        
        setColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
    
    @MainActor
    private func contactUsAction() {
        Task {
            dialogService.showProgress(withMessage: nil, userInteractionEnable: false)

            do {
                let account = try await accountsProvider.getAccount(byAddress: AdamantContacts.iosSupport.address)

                guard let chatroom = account.chatroom,
                      let nav = self.navigationController,
                      let account = self.accountService.account,
                      let chat = router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
                    return
                }

                chat.hidesBottomBarWhenPushed = true
                chat.viewModel.setup(
                    account: account,
                    chatroom: chatroom,
                    messageToShow: nil,
                    preservationDelegate: self
                )

                nav.pushViewController(chat, animated: true)

                dialogService.dismissProgress()
            } catch let error as AccountsProviderError {
                switch error {
                case .invalidAddress, .notFound, .notInitiated, .networkError, .dummy:
                    dialogService.showWarning(withMessage: String.adamantLocalized.sharedErrors.networkError)

                case .serverError(let error):
                    dialogService.showError(
                        withMessage:
                            String.adamantLocalized.sharedErrors.remoteServerError(
                                message: error.localizedDescription
                            ),
                        error: error
                    )
                }
            } catch {
                dialogService.showError(
                    withMessage:
                        String.adamantLocalized.sharedErrors.remoteServerError(
                            message: error.localizedDescription
                        ),
                    error: error
                )
            }
        }
    }
}

// MARK: - Tools
extension AboutViewController {
    fileprivate func buildUrlRow(title: String, value: String?, tag: String, url urlRaw: String, image: UIImage?) -> LabelRow {
        let row = LabelRow {
            $0.tag = tag
            $0.title = title
            $0.value = value
            $0.cell.imageView?.image = image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, row) in
            guard let url = URL(string: urlRaw) else {
                fatalError("Failed to build page url: \(urlRaw)")
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            self?.present(safari, animated: true, completion: nil)
            
            row.deselect()
        }
        
        return row
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension AboutViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - ChatViewControllerDelegate

extension AboutViewController: ChatPreservationDelegate {
    func preserveMessage(_ message: String, forAddress address: String) {
        storedIOSSupportMessage = message
    }

    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String? {
        if thenRemoveIt {
            let message = storedIOSSupportMessage
            storedIOSSupportMessage = nil
            return message
        } else {
            return storedIOSSupportMessage
        }
    }
}
