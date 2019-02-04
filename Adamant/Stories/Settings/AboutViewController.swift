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
		case adm, email, bitcointalk, facebook, telegram, vk, twitter
		
		var tag: String {
			switch self {
			case .website: return "www"
			case .whitepaper: return "whtpaper"
			case .github: return "git"
            case .welcomeScreens: return "welcome"
			case .adm: return "amd"
			case .email: return "email"
			case .blog: return "blog"
			case .bitcointalk: return "bittlk"
			case .facebook: return "fcbook"
			case .telegram: return "telegram"
			case .vk: return "vk"
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
			case .bitcointalk: return NSLocalizedString("About.Row.Bitcointalk", comment: "About scene: Bitcointalk.org row")
			case .facebook: return NSLocalizedString("About.Row.Facebook", comment: "About scene: Facebook row")
			case .telegram: return NSLocalizedString("About.Row.Telegram", comment: "About scene: Telegram row")
			case .vk: return NSLocalizedString("About.Row.VK", comment: "About scene: VK row")
			case .twitter: return NSLocalizedString("About.Row.Twitter", comment: "About scene: Twitter row")
			}
		}
		
		var localizedUrl: String {
			switch self {
			case .website: return NSLocalizedString("About.Row.Website.Url", comment: "About scene: Website localized url")
			case .whitepaper: return NSLocalizedString("About.Row.Whitepaper.Url", comment: "About scene: The Whitepaper localized url")
			case .github: return NSLocalizedString("About.Row.GitHub.Url", comment: "About scene: Project's GitHub page localized url")
			case .blog: return NSLocalizedString("About.Row.Blog.Url", comment: "About scene: Our blog localized url")
			case .bitcointalk: return NSLocalizedString("About.Row.Bitcointalk.Url", comment: "About scene: Bitcointalk.org localized url")
			case .facebook: return NSLocalizedString("About.Row.Facebook.Url", comment: "About scene: Facebook localized url")
			case .telegram: return NSLocalizedString("About.Row.Telegram.Url", comment: "About scene: Telegram localized url")
			case .vk: return NSLocalizedString("About.Row.VK.Url", comment: "About scene: VK localized url")
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
			default: return #imageLiteral(resourceName: "row_icon_placeholder")
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
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
        
		navigationItem.title = String.adamantLocalized.about.title
        
        tableView.setStyle(.baseTable)
        navigationController?.navigationBar.setStyle(.baseNavigationBar)
        view.style = AdamantThemeStyle.primaryTintAndBackground
		
		// MARK: Header & Footer
		if let header = UINib(nibName: "LogoFullHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			tableView.tableHeaderView = header
			
			if let label = header.viewWithTag(888) as? UILabel {
				label.text = String.adamantLocalized.shared.productName
				label.textColor = UIColor.adamant.primary
                label.setStyle(.primaryText)
			}
		}
		
		if let footer = UINib(nibName: "VersionFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			if let label = footer.viewWithTag(555) as? UILabel {
				label.text = AdamantUtilities.applicationVersion
				label.textColor = UIColor.adamant.primary
                label.setStyle(.primaryText)
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
		
		// Github
		<<< buildUrlRow(title: Rows.github.localized,
						value: nil,
						tag: Rows.github.tag,
						url: Rows.github.localizedUrl,
						image: Rows.github.image)

        // Welcome screens
        <<< LabelRow() {
            $0.title = Rows.welcomeScreens.localized
            $0.tag = Rows.welcomeScreens.tag
            $0.cell.imageView?.image = Rows.welcomeScreens.image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
            cell.setStyles([.secondaryBackground, .primaryTint])
            cell.textLabel?.setStyle(.primaryText)
            cell.imageView?.setStyle(.primaryTint)
        }.onCellSelection { [weak self] (_, _) in
            guard let vc = self?.router.get(scene: AdamantScene.Onboard.welcome) else {
                if let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                return
            }
            
            self?.present(vc, animated: true, completion: nil)
        }
			
		// MARK: Contact
		+++ Section(Sections.contactUs.localized) {
			$0.tag = Sections.contactUs.tag
		}
			
		// Adamant
		<<< LabelRow() {
			$0.title = Rows.adm.localized
			$0.tag = Rows.adm.tag
			$0.cell.imageView?.image = Rows.adm.image
			$0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
			$0.cell.selectionStyle = .gray
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
            cell.setStyles([.secondaryBackground, .primaryTint])
            cell.textLabel?.setStyle(.primaryText)
            cell.imageView?.setStyle(.primaryTint)
		}.onCellSelection { [weak self] (_, _) in
			guard let accountsProvider = self?.accountsProvider, let router = self?.router else {
				return
			}
			
			let dialogService = self?.dialogService
			dialogService?.showProgress(withMessage: nil, userInteractionEnable: false)
			
			accountsProvider.getAccount(byAddress: AdamantContacts.iosSupport.address) { result in
				switch result {
				case .success(let account):
					DispatchQueue.main.async {
						guard let chatroom = account.chatroom,
							let nav = self?.navigationController,
							let account = self?.accountService.account,
							let chat = router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
								return
						}
						
						chat.account = account
						chat.hidesBottomBarWhenPushed = true
						chat.chatroom = chatroom
						chat.delegate = self
						
						nav.pushViewController(chat, animated: true)
						
						dialogService?.dismissProgress()
					}
                    
				case .invalidAddress, .notFound, .notInitiated(_), .networkError, .dummy(_):
					dialogService?.showWarning(withMessage: String.adamantLocalized.sharedErrors.networkError)
					
				case .serverError(let error):
					dialogService?.showError(withMessage: String.adamantLocalized.sharedErrors.remoteServerError(message: error.localizedDescription), error: error)
				}
			}
		}
			
		// E-mail
		<<< LabelRow() {
			$0.title = Rows.email.localized
			$0.value = AdamantResources.supportEmail
			$0.tag = Rows.email.tag
			$0.cell.imageView?.image = Rows.email.image
			$0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
			$0.cell.selectionStyle = .gray
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
            cell.setStyles([.secondaryBackground, .primaryTint])
            cell.textLabel?.setStyle(.primaryText)
            cell.detailTextLabel?.setStyle(.primaryText)
            cell.imageView?.setStyle(.primaryTint)
		}.onCellSelection { [weak self] (_, _) in
			let mailVC = MFMailComposeViewController()
			mailVC.mailComposeDelegate = self
			mailVC.setToRecipients([AdamantResources.supportEmail])
			
			let systemVersion = UIDevice.current.systemVersion
			let model = AdamantUtilities.deviceModelCode
			let deviceInfo = "\n\n\nModel: \(model)\n" + "iOS: \(systemVersion)\n" + "App version: \(AdamantUtilities.applicationVersion)"
			
			mailVC.setSubject("ADAMANT iOS")
			mailVC.setMessageBody(deviceInfo, isHTML: false)
			self?.present(mailVC, animated: true, completion: nil)
		}
		
			
		/*
		// Bitcointalk
		<<< buildUrlRow(title: Rows.bitcointalk.localized,
						value: nil,
						tag: Rows.bitcointalk.tag,
						url: Rows.bitcointalk.localizedUrl,
						image: Rows.bitcointalk.image)
		
		// Facebook
		<<< buildUrlRow(title: Rows.facebook.localized,
						value: nil,
						tag: Rows.facebook.tag,
						url: Rows.facebook.localizedUrl,
						image: Rows.facebook.image)
		
		// Telegram
		<<< buildUrlRow(title: Rows.telegram.localized,
						value: nil,
						tag: Rows.telegram.tag,
						url: Rows.telegram.localizedUrl,
						image: Rows.telegram.image)
		
		// VK
		<<< buildUrlRow(title: Rows.vk.localized,
						value: nil,
						tag: Rows.vk.tag,
						url: Rows.vk.localizedUrl,
						image: Rows.vk.image)
		
		// Twitter
		<<< buildUrlRow(title: Rows.twitter.localized,
						value: nil,
						tag: Rows.twitter.tag,
						url: Rows.twitter.localizedUrl,
						image: Rows.twitter.image)
		*/
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
}


// MARK: - Tools
extension AboutViewController {
	fileprivate func buildUrlRow(title: String, value: String?, tag: String, url urlRaw: String, image: UIImage?) -> LabelRow {
		let row = LabelRow() {
			$0.tag = tag
			$0.title = title
			$0.value = value
			$0.cell.imageView?.image = image
			$0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
			$0.cell.selectionStyle = .gray
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
            cell.setStyles([.secondaryBackground, .primaryTint])
            cell.textLabel?.setStyle(.primaryText)
            cell.detailTextLabel?.setStyle(.primaryText)
            cell.imageView?.setStyle(.primaryTint)
		}.onCellSelection { [weak self] (_, _) in
			guard let url = URL(string: urlRaw) else {
				fatalError("Failed to build page url: \(urlRaw)")
			}
			
			let safari = SFSafariViewController(url: url)
			safari.preferredControlTintColor = UIColor.adamant.primary
            safari.preferredBarTintColor = UIColor.adamant.secondaryBackground
			self?.present(safari, animated: true, completion: nil)
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
extension AboutViewController: ChatViewControllerDelegate {
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
