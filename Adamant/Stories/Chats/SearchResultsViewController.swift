//
//  SearchResultsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject
import Haring

extension String.adamantLocalized {
    struct search {
        static let contacts = NSLocalizedString("SearchPage.Contacts", comment: "SearchPage: Contacts header")
        static let messages = NSLocalizedString("SearchPage.Messages", comment: "SearchPage: Messages header")
        
        private init() {}
    }
}

protocol SearchResultDelegate {
    func didSelected(_ message: MessageTransaction)
    func didSelected(_ contact: Chatroom)
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
    
    var delegate: SearchResultDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        
        tableView.register(UINib(nibName: "ChatTableViewCell", bundle: nil), forCellReuseIdentifier: "resultCell")
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
        if self.contacts.count > 0, self.messages.count > 0 {
            return section == 0 ? self.contacts.count : self.messages.count
        } else if self.contacts.count > 0 {
            return self.contacts.count
        } else if self.messages.count > 0 {
            return self.messages.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as! ChatTableViewCell

        if self.contacts.count > 0, self.messages.count > 0 {
            if indexPath.section == 0  {
                let value = contacts[indexPath.row]
                configureCell(cell, for: value)
            } else {
                let value = messages[indexPath.row]
                configureCell(cell, for: value)
            }
        } else if self.contacts.count > 0 {
            let value = contacts[indexPath.row]
            configureCell(cell, for: value)
        } else if self.messages.count > 0 {
            let value = messages[indexPath.row]
            configureCell(cell, for: value)
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
            
            if let avatarName = partner.avatar, let avatar = UIImage.init(named: avatarName) {
                cell.avatarImage = avatar
                cell.avatarImageView.tintColor = UIColor.adamant.primary
            } else {
                if let address = partner.publicKey {
                    DispatchQueue.global().async {
                        let image = self.avatarService.avatar(for: address, size: 200)
                        DispatchQueue.main.async {
                            cell.avatarImage = image
                        }
                    }
                    
                    cell.avatarImageView.roundingMode = .round
                    cell.avatarImageView.clipsToBounds = true
                } else {
                    cell.avatarImage = nil
                }
                cell.borderWidth = 0
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
                    DispatchQueue.global().async {
                        let image = self.avatarService.avatar(for: address, size: 200)
                        DispatchQueue.main.async {
                            cell.avatarImage = image
                        }
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
            
            if let ranges = raw.range(of: searchText, options: .caseInsensitive) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.adamant.active,
                    ]
                
                attributedString.addAttributes(attributes, range: NSRange(ranges, in: raw))
            }
            
            return attributedString
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if self.contacts.count > 0, self.messages.count > 0 {
            if indexPath.section == 0  {
                let value = contacts[indexPath.row]
                delegate?.didSelected(value)
            } else {
                let value = messages[indexPath.row]
                delegate?.didSelected(value)
            }
        } else if self.contacts.count > 0 {
            let value = contacts[indexPath.row]
            delegate?.didSelected(value)
        } else if self.messages.count > 0 {
            let value = messages[indexPath.row]
            delegate?.didSelected(value)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.contacts.count > 0, self.messages.count > 0 {
            if section == 0  {
                return String.adamantLocalized.search.contacts
            } else {
                return String.adamantLocalized.search.messages
            }
        }
        
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.contacts.count > 0, self.messages.count > 0 {
            if indexPath.section == 0  {
                return 60
            } else {
                return 80
            }
        } else if self.contacts.count > 0 {
            return 60
        } else if self.messages.count > 0 {
            return 80
        }
        
        return 0
    }
}
