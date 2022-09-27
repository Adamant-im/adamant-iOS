//
//  AdmTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData

class AdmTransactionsViewController: TransactionsListViewControllerBase {
    // MARK: - Dependencies
    var accountService: AccountService!
    var transfersProvider: TransfersProvider!
    var chatsProvider: ChatsProvider!
    var dialogService: DialogService!
    var stack: CoreDataStack!
    var router: Router!
    
    // MARK: - Properties
    var controller: NSFetchedResultsController<TransferTransaction>?
    
    /*
     In SplitViewController on iPhones, viewController can still present in memory, but not on screen.
     In this cases not visible viewController will still mark messages isUnread = false
     */
    /// ViewController currently is ontop of the screen.
    private var isOnTop = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if accountService.account != nil {
            reloadData()
        }
        
        currencySymbol = AdmWalletService.currencySymbol
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isOnTop = true
        markTransfersAsRead()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isOnTop = false
    }
    
    // MARK: - Overrides
    
    override func reloadData() {
        controller = transfersProvider.transfersController()
        controller!.delegate = self
        
        do {
            try controller?.performFetch()
        } catch {
            dialogService.showError(withMessage: "Failed to get transactions. Please, report a bug", error: error)
            controller = nil
        }
        
        DispatchQueue.onMainAsync {
            self.tableView.reloadData()
        }
    }
    
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.emptyLabel.isHidden = true
        self.transfersProvider.update { [weak self] (result) in
            guard let result = result else {
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
                }
                return
            }
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
                }
                
                self?.dialogService.showRichError(error: error)
            }
        }
    }
    
    private func markTransfersAsRead() {
        guard let stack = stack else {
            return
        }
        DispatchQueue.global(qos: .utility).async {
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = stack.container.viewContext
            
            let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
            request.predicate = NSPredicate(format: "isUnread == true")
            request.sortDescriptors = [NSSortDescriptor(key: "transactionId", ascending: false)]
            
            if let result = try? privateContext.fetch(request) {
                result.forEach { $0.isUnread = false }
                
                if privateContext.hasChanges {
                    try? privateContext.save()
                }
            }
        }
    }
    
    // MARK: - UITableView

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let f = controller?.fetchedObjects {
            self.emptyLabel.isHidden = f.count > 0 && !refreshControl.isRefreshing
            return f.count
        } else {
            self.emptyLabel.isHidden = false
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let transaction = controller?.object(at: indexPath) else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        guard let controller = router.get(scene: AdamantScene.Wallets.Adamant.transactionDetails) as? AdmTransactionDetailsViewController else {
            return
        }
        
        controller.transaction = transaction
        controller.comment = transaction.comment
        
        controller.showToChat = toShowChat(for: transaction)
        
        if let address = accountService.account?.address {
            if address == transaction.senderId {
                controller.senderName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                controller.senderName = transaction.chatroom?.partner?.name
            }
            
            if address == transaction.recipientId {
                controller.recipientName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                controller.recipientName = transaction.chatroom?.partner?.name
            }
        }
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: TransferTransaction) {
        let partnerId = (transaction.isOutgoing ? transaction.recipientId : transaction.senderId) ?? ""
        
        let amount: Decimal = transaction.amount as Decimal? ?? 0
        
        configureCell(cell,
                      isOutgoing: transaction.isOutgoing,
                      partnerId: partnerId,
                      partnerName: transaction.chatroom?.partner?.name,
                      amount: amount,
                      date: transaction.date as Date?)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let transaction = controller?.object(at: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let identifier = transaction.chatroom?.partner?.name != nil ? cellIdentifierFull : cellIdentifierCompact
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? TransactionTableViewCell else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        configureCell(cell, for: transaction)
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        guard let transaction = controller?.object(at: editActionsForRowAt), let partner = transaction.partner as? CoreDataAccount, let chatroom = partner.chatroom, let transactions = chatroom.transactions  else {
            return nil
        }
        
        let messeges = transactions.first(where: { (object) -> Bool in
            return !(object is TransferTransaction)
        })
        
        let title = (messeges != nil) ? String.adamantLocalized.transactionList.toChat : String.adamantLocalized.transactionList.startChat
        
        let toChat = UITableViewRowAction(style: .normal, title: title) { _, _ in
            guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
                // TODO: Log this
                return
            }
            
            guard let account = self.accountService.account else {
                return
            }
            
            vc.account = account
            vc.chatroom = chatroom
            vc.hidesBottomBarWhenPushed = true
            
            if let nav = self.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true)
            }
        }
        
        toChat.backgroundColor = UIColor.adamant.primary
        
        return [toChat]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let transaction = controller?.object(at: indexPath) else {
            return false
        }
        
        return toShowChat(for: transaction)
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let transaction = controller?.object(at: indexPath), let partner = transaction.partner as? CoreDataAccount, let chatroom = partner.chatroom, let transactions = chatroom.transactions  else {
            return nil
        }
        
        let messeges = transactions.first(where: { (object) -> Bool in
            return !(object is TransferTransaction)
        })
        
        let title = (messeges != nil) ? String.adamantLocalized.transactionList.toChat : String.adamantLocalized.transactionList.startChat
        
        let toChat = UIContextualAction(style: .normal, title:  title, handler: { (_, _, _) in
            guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
                // TODO: Log this
                return
            }
            
            guard let account = self.accountService.account else {
                return
            }
            
            vc.account = account
            vc.chatroom = chatroom
            vc.hidesBottomBarWhenPushed = true
            
            if let nav = self.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true)
            }
        })
        
        toChat.image = #imageLiteral(resourceName: "chats_tab")
        toChat.backgroundColor = UIColor.adamant.primary
        return UISwipeActionsConfiguration(actions: [toChat])
    }
    
    private func toShowChat(for transaction: TransferTransaction) -> Bool {
        guard let partner = transaction.partner as? CoreDataAccount, let chatroom = partner.chatroom, !chatroom.isReadonly else {
            return false
        }
        
        return true
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AdmTransactionsViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                
                if isOnTop, let transaction = anObject as? TransferTransaction {
                    transaction.isUnread = false
                }
            }
            
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
        case .update:
            if let indexPath = indexPath,
                let cell = self.tableView.cellForRow(at: indexPath) as? TransactionTableViewCell,
                let transaction = anObject as? TransferTransaction {
                configureCell(cell, for: transaction)
            }
            
        case .move:
            if let at = indexPath, let to = newIndexPath {
                tableView.moveRow(at: at, to: to)
            }
        @unknown default:
            break
        }
    }
}
