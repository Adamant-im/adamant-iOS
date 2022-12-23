//
//  SearchResultsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject
import MarkdownKit

extension String.adamantLocalized {
    struct search {
        static let contacts = NSLocalizedString("SearchPage.Contacts", comment: "SearchPage: Contacts header")
        static let messages = NSLocalizedString("SearchPage.Messages", comment: "SearchPage: Messages header")
        
        private init() {}
    }
}

protocol SearchResultDelegate: AnyObject {
    func didSelected(_ message: MessageTransaction)
    func didSelected(_ chatroom: Chatroom)
}

class SearchResultsViewController: UITableViewController {
    
    // MARK: - Dependencies
    var router: Router!
    var avatarService: AvatarService!
    
    // MARK: Properties
    private var contacts: [Chatroom] = [Chatroom]()
    private var messages: [MessageTransaction] = [MessageTransaction]()
    private var searchText: String = ""
    
    private let markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: ChatTableViewCell.shortDescriptionTextSize))
    
    weak var delegate: SearchResultDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView.register(UINib(nibName: "ChatTableViewCell", bundle: nil), forCellReuseIdentifier: "resultCell")
        setColors()
    }
    
    // MARK: - Other
    
    func setColors() {
        view.backgroundColor = UIColor.adamant.backgroundColor
    }
    
    func updateResult(contacts: [Chatroom]?, messages: [MessageTransaction]?, searchText: String) {
        self.contacts = contacts ?? [Chatroom]()
        self.messages = messages ?? [MessageTransaction]()
        self.searchText = searchText
        
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        var sections: Int = 0
        if self.contacts.count > 0 {
            sections += 1
        }
        if self.messages.count > 0 {
            sections += 1
        }
        return sections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch defineSection(for: section) {
        case .contacts: return contacts.count
        case .messages: return messages.count
        case .none: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as! ChatTableViewCell
        
        switch defineSection(for: indexPath) {
        case .contacts:
            let contact = contacts[indexPath.row]
            cell.lastMessageLabel.textColor = UIColor.adamant.primary
            configureCell(cell, for: contact)
            
        case .messages:
            let message = messages[indexPath.row]
            cell.lastMessageLabel.textColor = nil // Managed by NSAttributedText
            configureCell(cell, for: message)
            
        case .none:
            break
        }
        
        return cell
    }
    
    private func configureCell(_ cell: ChatTableViewCell, for chatroom: Chatroom) {
        if let partner = chatroom.partner {
            if let title = chatroom.title {
                cell.accountLabel.text = title
                cell.lastMessageLabel.text = partner.address
            } else if let name = partner.name {
                cell.accountLabel.text = name
                cell.lastMessageLabel.text = partner.address
            } else {
                cell.accountLabel.text = nil
                cell.lastMessageLabel.text = partner.address
            }
            
            cell.avatarImageView.tintColor = UIColor.adamant.primary
            cell.avatarImageView.roundingMode = .round
            cell.avatarImageView.clipsToBounds = true
            cell.borderWidth = 0
            
            if let avatarName = partner.avatar, let avatar = UIImage.init(named: avatarName) {
                cell.avatarImage = avatar
            } else if let publicKey = partner.publicKey {
                let image = avatarService.avatar(for: publicKey, size: 200)
                cell.avatarImage = image
            } else {
                cell.avatarImage = nil
            }
        } else if let title = chatroom.title {
            cell.accountLabel.text = nil
            cell.lastMessageLabel.text = title
        }
        
        cell.hasUnreadMessages = false
        cell.dateLabel.text = nil
    }
    
    private func configureCell(_ cell: ChatTableViewCell, for message: MessageTransaction) {
        if let partner = message.chatroom?.partner {
            if let title = message.chatroom?.title {
                cell.accountLabel.text = title
            } else if let name = partner.name {
                cell.accountLabel.text = name
            } else {
                cell.accountLabel.text = partner.address
            }
            
            if let avatarName = partner.avatar, let avatar = UIImage.init(named: avatarName) {
                cell.avatarImage = avatar
                cell.avatarImageView.tintColor = UIColor.adamant.primary
            } else {
                if let address = partner.publicKey {
                    let image = self.avatarService.avatar(for: address, size: 200)
                    
                    DispatchQueue.onMainAsync {
                        cell.avatarImage = image
                    }
                    
                    cell.avatarImageView.roundingMode = .round
                    cell.avatarImageView.clipsToBounds = true
                } else {
                    cell.avatarImage = nil
                }
                cell.borderWidth = 0
            }
        } else if let title = message.chatroom?.title {
            cell.accountLabel.text = title
        }
        
        cell.hasUnreadMessages = false
        
        cell.lastMessageLabel.attributedText = shortDescription(for: message)
        
        if let date = message.sentDate as Date?, date != Date.adamantNullDate {
            cell.dateLabel.text = date.humanizedDay()
        } else {
            cell.dateLabel.text = nil
        }
    }
    
    private func shortDescription(for transaction: ChatTransaction) -> NSAttributedString? {
        switch transaction {
        case let message as MessageTransaction:
            guard let text = message.message else {
                return nil
            }
            
            let raw: String
            if message.isOutgoing {
                raw = "\(String.adamantLocalized.chatList.sentMessagePrefix)\(text)"
            } else {
                raw = text
            }
            
            let attributedString = markdownParser.parse(raw).mutableCopy() as! NSMutableAttributedString
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.adamant.primary,
                                          range: NSRange(location: 0, length: attributedString.length))
            
            if let ranges = attributedString.string.range(of: searchText, options: .caseInsensitive) {
                attributedString.addAttribute(.foregroundColor,
                                              value: UIColor.adamant.active,
                                              range: NSRange(ranges, in: attributedString.string))
            }
            
            return attributedString
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let delegate = delegate else {
            return
        }
        
        switch defineSection(for: indexPath) {
        case .contacts:
            let contact = contacts[indexPath.row]
            delegate.didSelected(contact)
            
        case .messages:
            let message = messages[indexPath.row]
            delegate.didSelected(message)
            
        case .none:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch defineSection(for: section) {
        case .contacts: return String.adamantLocalized.search.contacts
        case .messages: return String.adamantLocalized.search.messages
        case .none: return nil
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch defineSection(for: indexPath) {
        case .contacts: return 60
        case .messages: return 80
        case .none: return 60
        }
    }
    
    // MARK: - Working with sections
    private enum Section {
        case contacts
        case messages
        case none
    }
    
    private func defineSection(for indexPath: IndexPath) -> Section {
        return defineSection(for: indexPath.section)
    }
    
    private func defineSection(for section: Int) -> Section {
        if self.contacts.count > 0, self.messages.count > 0 {
            if section == 0 {
                return .contacts
            } else {
                return .messages
            }
        } else if self.contacts.count > 0 {
            return .contacts
        } else if self.messages.count > 0 {
            return .messages
        } else {
            return .none
        }
    }
}
