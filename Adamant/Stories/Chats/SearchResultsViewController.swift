//
//  SearchResultsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import  Swinject

protocol SearchResultDelegate {
    func didSelected(_ message: MessageTransaction )
}

class SearchResultsViewController: UITableViewController {
    
    // MARK: - Dependencies
    var router: Router!
    var avatarService: AvatarService!
    
    // MARK: Properties
    private var result: [MessageTransaction] = [MessageTransaction]()
    
    var delegate: SearchResultDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "ChatTableViewCell", bundle: nil), forCellReuseIdentifier: "resultCell")
        
//        self.tableView.rowHeight = UITableView.automaticDimension
//        self.tableView.estimatedRowHeight = 60.0
        
    }
    
    func updateResult(newResults: [MessageTransaction]) {
        result = newResults
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as! ChatTableViewCell

        let value = result[indexPath.row]
        configureCell(cell, for: value)

        return cell
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
        
        cell.lastMessageLabel.text = message.message
        
        if let date = message.sentDate as Date?, date != Date.adamantNullDate {
            cell.dateLabel.text = date.humanizedDay()
        } else {
            cell.dateLabel.text = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let value = result[indexPath.row]
        delegate?.didSelected(value)
    }

}
