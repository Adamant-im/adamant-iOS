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
import CommonKit

// MARK: - Localization
extension String.adamant {
    enum about {
        static var title: String {
            String.localized("About.Title", comment: "About page: scene title")
        }
        
        static func commit(_ commit: String) -> String {
            String.localizedStringWithFormat(
                String.localized(
                    "About.Version.Commit",
                    comment: "Commit Hash"
                ),
                commit
            )
        }
    }
}

// MARK: - AboutViewController
final class AboutViewController: FormViewController {
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
            case .about: return .localized("About.Section.About", comment: "About scene: 'Read about' section title.")
            case .contactUs: return .localized("About.Section.ContactUs", comment: "About scene: 'Contact us' section title.")
            }
        }
    }
    
    enum Rows {
        case website, whitepaper, blog, github, welcomeScreens
        case adm, email, twitter, vibration
        
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
            case .vibration: return "vibration"
            }
        }
        
        var localized: String {
            switch self {
            case .website: return .localized("About.Row.Website", comment: "About scene: Website row")
            case .whitepaper: return .localized("About.Row.Whitepaper", comment: "About scene: The Whitepaper row")
            case .github: return .localized("About.Row.GitHub", comment: "About scene: Project's GitHub page row")
            case .adm: return .localized("About.Row.Adamant", comment: "About scene: Write to Adamant row")
            case .welcomeScreens: return .localized("About.Row.Welcome", comment: "About scene: Show Welcome screens")
            case .email: return .localized("About.Row.WriteUs", comment: "About scene: Write us row")
            case .blog: return .localized("About.Row.Blog", comment: "About scene: Our blog row")
            case .twitter: return .localized("About.Row.Twitter", comment: "About scene: Twitter row")
            case .vibration: return "Vibrations"
            }
        }
        
        var localizedUrl: String {
            switch self {
            case .website: return .localized("About.Row.Website.Url", comment: "About scene: Website localized url")
            case .whitepaper: return .localized("About.Row.Whitepaper.Url", comment: "About scene: The Whitepaper localized url")
            case .github: return .localized("About.Row.GitHub.Url", comment: "About scene: Project's GitHub page localized url")
            case .blog: return .localized("About.Row.Blog.Url", comment: "About scene: Our blog localized url")
            case .twitter: return .localized("About.Row.Twitter.Url", comment: "About scene: Twitter localized url")
                
            // No urls
            case .adm, .email, .welcomeScreens, .vibration: return ""
            }
        }
        
        var image: UIImage? {
            switch self {
            case .whitepaper: return .asset(named: "row_whitepapper")
            case .email: return .asset(named: "row_email")
            case .github: return .asset(named: "row_github")
            case .blog: return .asset(named: "row_blog")
            case .adm: return .asset(named: "row_chat_adamant")
            case .website: return .asset(named: "row_website")
            case .welcomeScreens: return .asset(named: "row_logo")
            case .twitter: return .asset(named: "row_twitter")
            case .vibration: return .asset(named: "row_vibration")
            }
        }
    }
    
    // MARK: Dependencies
    
    private let accountService: AccountService
    private let accountsProvider: AccountsProvider
    private let dialogService: DialogService
    private let screensFactory: ScreensFactory
    private let vibroService: VibroService
    
    // MARK: Properties
    
    private var storedIOSSupportMessage: String?
    private var numerOfTap = 0
    private let maxNumerOfTap = 10
    
    private lazy var versionFooterView = VersionFooterView()
    
    // MARK: Init
    
    init(
        accountService: AccountService,
        accountsProvider: AccountsProvider,
        dialogService: DialogService,
        screensFactory: ScreensFactory,
        vibroService: VibroService
    ) {
        self.accountService = accountService
        self.accountsProvider = accountsProvider
        self.dialogService = dialogService
        self.screensFactory = screensFactory
        self.vibroService = vibroService
        
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = String.adamant.about.title
        tableView.tableFooterView = versionFooterView
        setVersion()
        
        // MARK: Header & Footer
        if let header = UINib(nibName: "LogoFullHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
            
            let tapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(tapAction)
            )
            header.addGestureRecognizer(tapGestureRecognizer)
            
            tableView.tableHeaderView = header
            
            if let label = header.viewWithTag(888) as? UILabel {
                label.text = String.adamant.shared.productName
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
            guard let self = self else { return }
            let vc = self.screensFactory.makeOnboard()
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true, completion: nil)
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
        }.onCellSelection { [weak self] (_, row) in
            self?.openEmailScreen(
                recipient: AdamantResources.supportEmail,
                subject: "ADAMANT Support",
                body: "\n\n\n" + AdamantUtilities.deviceInfo,
                delegate: self
            )
            
            row.deselect()
        }
        
        setColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
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
    
    @MainActor
    private func contactUsAction() {
        Task {
            dialogService.showProgress(withMessage: nil, userInteractionEnable: false)

            do {
                let account = try await accountsProvider.getAccount(byAddress: AdamantContacts.adamantSupport.address)

                guard
                    let chatroom = account.chatroom,
                    let nav = navigationController,
                    let account = accountService.account
                else { return }

                let chat = screensFactory.makeChat()
                chat.hidesBottomBarWhenPushed = true
                chat.viewModel.setup(
                    account: account,
                    chatroom: chatroom,
                    messageIdToShow: nil
                )

                nav.pushViewController(chat, animated: true)

                dialogService.dismissProgress()
            } catch let error as AccountsProviderError {
                switch error {
                case .invalidAddress, .notFound, .notInitiated, .networkError, .dummy:
                    dialogService.showWarning(withMessage: String.adamant.sharedErrors.networkError)

                case .serverError(let error):
                    dialogService.showError(
                        withMessage:
                            String.adamant.sharedErrors.remoteServerError(
                                message: error.localizedDescription
                            ),
                        supportEmail: false,
                        error: error
                    )
                }
            } catch {
                dialogService.showError(
                    withMessage:
                        String.adamant.sharedErrors.remoteServerError(
                            message: error.localizedDescription
                        ),
                    supportEmail: false,
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

private extension AboutViewController {
    @objc func tapAction() {
        numerOfTap += 1
        
        guard numerOfTap == maxNumerOfTap else {
            return
        }
        
        vibroService.applyVibration(.success)
        addVibrationRow()
    }
    
    func addVibrationRow() {
        guard let appSection = form.sectionBy(tag: Sections.contactUs.tag),
              form.rowBy(tag: Rows.vibration.tag) == nil
        else { return }
        
        let vibrationRow = LabelRow {
            $0.title = Rows.vibration.localized
            $0.tag = Rows.vibration.tag
            $0.cell.imageView?.image = Rows.vibration.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let vc = self?.screensFactory.makeVibrationSelection()
            else {
                return
            }
            
            if let split = self?.splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = self?.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                self?.present(vc, animated: true, completion: nil)
            }
        }
        
        appSection.append(vibrationRow)
    }
    
    func setVersion() {
        versionFooterView.model = .init(
            version: AdamantUtilities.applicationVersion,
            commit: AdamantUtilities.Git.commitHash.map {
                .adamant.about.commit(.init($0.prefix(20)))
            }
        )
    }
}
