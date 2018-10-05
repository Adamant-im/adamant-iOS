//
//  AdmTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class AdmTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    
    // MARK: - Dependencies
    var accountService: AccountService!
    var transfersProvider: TransfersProvider!
    var router: Router!
    
    // MARK: - Properties
    private let autoupdateInterval: TimeInterval = 5.0
    
    var haveChatroom = false
    
    weak var timer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        currencySymbol = AdmWalletService.currencySymbol
        
        super.viewDidLoad()
        
        if let transfer = transaction as? TransferTransaction, let chatroom = transfer.partner?.chatroom, let transactions = chatroom.transactions  {
            let messeges = transactions.first (where: { (object) -> Bool in
                return !(object is TransferTransaction)
            })
            
            haveChatroom = messeges != nil
        }
        
        let chatLabel = haveChatroom ? String.adamantLocalized.transactionList.toChat : String.adamantLocalized.transactionList.startChat
        
        // MARK: Open chat
        if let section = form.allSections.first {
            let row = LabelRow() {
                $0.tag = Rows.openChat.tag
                $0.title = chatLabel
                $0.cell.imageView?.image = Rows.openChat.image
            }.cellSetup { (cell, _) in
                cell.selectionStyle = .gray
            }.cellUpdate { (cell, _) in
                cell.accessoryType = .disclosureIndicator
            }.onCellSelection { [weak self] (_, _) in
                self?.goToChat()
            }
            
            section.append(row)
        }
        
        startUpdate()
    }
    
    deinit {
        stopUpdate()
    }
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        return URL(string: "\(AdamantResources.adamantExplorerAddress)\(transaction.id)")
    }
    
    func goToChat() {
        guard let transfer = transaction as? TransferTransaction else {
            return
        }
        
        guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
            dialogService.showError(withMessage: "AdmTransactionDetailsViewController: Failed to get ChatViewController", error: nil)
            return
        }

        guard let chatroom = transfer.chatroom else {
            dialogService.showError(withMessage: "AdmTransactionDetailsViewController: Failed to get chatroom for transaction.", error: nil)
            return
        }

        guard let account = accountService.account else {
            dialogService.showError(withMessage: "AdmTransactionDetailsViewController: User not logged.", error: nil)
            return
        }

        vc.account = account
        vc.chatroom = chatroom
        vc.hidesBottomBarWhenPushed = true

        if let nav = self.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            self.present(vc, animated: true)
        }
    }
    
    // MARK: - Autoupdate
    
    func startUpdate() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: autoupdateInterval, repeats: true) { [weak self] _ in
            guard let id = self?.transaction?.id else {
                return
            }
            
            self?.transfersProvider.refreshTransfer(id: id) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    
                case .failure:
                    return
                }
            }
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
    }
}
