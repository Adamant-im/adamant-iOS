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

class AboutViewController: FormViewController {
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
			case .about: return "About"
			case .contactUs: return "Contact us"
			}
		}
	}
	
	enum Rows {
		case website, whitepaper, github
		case email, blog, bitcointalk, facebook, telegram, vk, twitter
		
		var tag: String {
			switch self {
			case .website: return "www"
			case .whitepaper: return "whtpaper"
			case .github: return "git"
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
			case .website: return "Website"
			case .whitepaper: return "The Whitepaper"
			case .github: return "Project's GitHub page"
			case .email: return "Write us"
			case .blog: return "Out blog"
			case .bitcointalk: return "Bitcointalk.org"
			case .facebook: return "Facebook"
			case .telegram: return "Telegram"
			case .vk: return "VK"
			case .twitter: return "Twitter"
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.navigationItem.title = "About"
		
		// MARK: Header & Footer
		if let header = UINib(nibName: "LogoFullHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			tableView.tableHeaderView = header
			
			if let label = header.viewWithTag(888) as? UILabel {
				label.text = String.adamantLocalized.shared.productName
				label.textColor = UIColor.adamantPrimary
			}
		}
		
		if let footer = UINib(nibName: "VersionFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			if let label = footer.viewWithTag(555) as? UILabel {
				label.text = AdamantUtilities.applicationVersion
				label.textColor = UIColor.adamantPrimary
				tableView.tableFooterView = footer
			}
		}
		
		
		// MARK: About
		form +++ Section(Sections.about.localized) {
			$0.tag = Sections.about.tag
		}
		
		// Website
		<<< buildUrlRow(title: Rows.website.localized,
						value: AdamantResources.adamantWebsite,
						tag: Rows.website.tag,
						url: AdamantResources.adamantWebsite,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))
			
		// Whitepaper
		<<< buildUrlRow(title: Rows.whitepaper.localized,
						value: nil,
						tag: Rows.whitepaper.tag,
						url: AdamantResources.adamantWhitepaper,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))
		
		// Github
		<<< buildUrlRow(title: Rows.github.localized,
						value: nil,
						tag: Rows.github.tag,
						url: AdamantResources.adamantGithubPage,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))

			
		// MARK: Contact
		+++ Section(Sections.contactUs.localized) {
			$0.tag = Sections.contactUs.tag
		}
			
		// E-mail
		<<< LabelRow() {
			$0.title = Rows.email.localized
			$0.value = AdamantResources.supportEmail
			$0.tag = Rows.email.tag
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
			$0.cell.selectionStyle = .gray
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ [weak self] (_, _) in
			let mailVC = MFMailComposeViewController()
			mailVC.mailComposeDelegate = self
			mailVC.setToRecipients([AdamantResources.supportEmail])
			
			let systemVersion = UIDevice.current.systemVersion
			let model = AdamantUtilities.deviceModelCode
			let deviceInfo = "\n\n\nModel: \(model)\n" + "iOS: \(systemVersion)\n" + "App version: \(AdamantUtilities.applicationVersion)"
			
			mailVC.setSubject("ADAMANT iOS")
			mailVC.setMessageBody(deviceInfo, isHTML: false)
			self?.present(mailVC, animated: true, completion: nil)
		})
		
		// Blog
		<<< buildUrlRow(title: Rows.blog.localized,
						value: nil,
						tag: Rows.blog.tag,
						url: AdamantResources.adamantBlogPage,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))
		
		// Bitcointalk
		<<< buildUrlRow(title: Rows.bitcointalk.localized,
						value: nil,
						tag: Rows.bitcointalk.tag,
						url: AdamantResources.adamantBitcointalkPage,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))
		
		// Facebook
		<<< buildUrlRow(title: Rows.facebook.localized,
						value: nil,
						tag: Rows.facebook.tag,
						url: AdamantResources.adamantFacebookPage,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))
		
		// Telegram
		<<< buildUrlRow(title: Rows.telegram.localized,
						value: nil,
						tag: Rows.telegram.tag,
						url: AdamantResources.adamantTelegram,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))
		
		// VK
		<<< buildUrlRow(title: Rows.vk.localized,
						value: nil,
						tag: Rows.vk.tag,
						url: AdamantResources.adamantVk,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))
		
		// Twitter
		<<< buildUrlRow(title: Rows.twitter.localized,
						value: nil,
						tag: Rows.twitter.tag,
						url: AdamantResources.adamantTwitter,
						image: #imageLiteral(resourceName: "row_icon_placeholder"))
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
			$0.cell.selectionStyle = .gray
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ [weak self] (_, _) in
			guard let url = URL(string: urlRaw) else {
				fatalError("Failed to build page url: \(urlRaw)")
			}
			
			let safari = SFSafariViewController(url: url)
			safari.preferredControlTintColor = UIColor.adamantPrimary
			self?.present(safari, animated: true, completion: nil)
		})
		
		return row
	}
}


// MARK: - MFMailComposeViewControllerDelegate
extension AboutViewController: MFMailComposeViewControllerDelegate {
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true, completion: nil)
	}
}
