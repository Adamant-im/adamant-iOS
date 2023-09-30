//
//  AdmTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData
import CommonKit

class AdmTransactionsViewController: TransactionsListViewControllerBase {
    // MARK: - Dependencies
    
    var accountService: AccountService
    var transfersProvider: TransfersProvider
    var chatsProvider: ChatsProvider
    var stack: CoreDataStack
    var router: Router
    var addressBookService: AddressBookService
    
    // MARK: - Properties
    
    var controller: NSFetchedResultsController<TransferTransaction>?
    
    /*
     In SplitViewController on iPhones, viewController can still present in memory, but not on screen.
     In this cases not visible viewController will still mark messages isUnread = false
     */
    /// ViewController currently is ontop of the screen.
    private var isOnTop = false
    private let transactionsPerRequest = 100
    
    // MARK: - Lifecycle
    
    init(
        nibName nibNameOrNil: String?,
        bundle nibBundleOrNil: Bundle?,
        accountService: AccountService,
        transfersProvider: TransfersProvider,
        chatsProvider: ChatsProvider,
        dialogService: DialogService,
        stack: CoreDataStack,
        router: Router,
        addressBookService: AddressBookService
    ) {
        self.accountService = accountService
        self.transfersProvider = transfersProvider
        self.chatsProvider = chatsProvider
        self.stack = stack
        self.router = router
        self.addressBookService = addressBookService
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.dialogService = dialogService
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    @MainActor
    override func reloadData() {
        Task {
            controller = await transfersProvider.transfersController()
            controller!.delegate = self
            
            do {
                try controller?.performFetch()
            } catch {
                dialogService.showError(withMessage: "Failed to get transactions. Please, report a bug", supportEmail: true, error: error)
                controller = nil
            }
            
            isBusy = false
            self.tableView.reloadData()
        }
    }
    
    @MainActor
    override func handleRefresh() {
        Task {
            self.isBusy = true
            self.emptyLabel.isHidden = true
            
            let result = await self.transfersProvider.update()
            
            guard let result = result else {
                refreshControl.endRefreshing()
                return
            }
            
            switch result {
            case .success:
                refreshControl.endRefreshing()
                tableView.reloadData()
                
            case .failure(let error):
                refreshControl.endRefreshing()
                
                dialogService.showRichError(error: error)
            }
            
            self.isBusy = false
        }.stored(in: taskManager)
    }
    
    override func loadData(silent: Bool) {
        isBusy = true
        emptyLabel.isHidden = true
        
        guard let address = accountService.account?.address else {
            return
        }
        
        Task { @MainActor in
            do {
                let count = try await transfersProvider.getTransactions(
                    forAccount: address,
                    type: .send,
                    offset: transfersProvider.offsetTransactions,
                    limit: transactionsPerRequest,
                    orderByTime: true
                )
                
                if count > 0 {
                    await transfersProvider.updateOffsetTransactions(
                        transfersProvider.offsetTransactions + transactionsPerRequest
                    )
                }
                
                isNeedToLoadMoore = count >= transactionsPerRequest
            } catch {
                isNeedToLoadMoore = false
                
                if !silent {
                    dialogService.showRichError(error: error)
                }
            }
            
            isBusy = false
            emptyLabel.isHidden = !isNeedToLoadMoore
            refreshControl.endRefreshing()
            stopBottomIndicator()
            tableView.reloadData()
        }.stored(in: taskManager)
    }
    
    private func markTransfersAsRead() {
        DispatchQueue.global(qos: .utility).async {
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = self.stack.container.viewContext
            
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
            let partnerName = addressBookService.getName(for: transaction.partner)
            
            if address == transaction.senderId {
                controller.senderName = String.adamant.transactionDetails.yourAddress
            } else {
                controller.senderName = partnerName
            }
            
            if address == transaction.recipientId {
                controller.recipientName = String.adamant.transactionDetails.yourAddress
            } else {
                controller.recipientName = partnerName
            }
        }
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func configureCell(
        _ cell: TransactionTableViewCell,
        for transaction: TransferTransaction
    ) {
        let partnerId = (transaction.isOutgoing ? transaction.recipientId : transaction.senderId) ?? ""
        
        let amount: Decimal = transaction.amount as Decimal? ?? 0
        
        var partnerName = addressBookService.getName(for: transaction.partner)
        
        if let address = accountService.account?.address, partnerId == address {
            partnerName = String.adamant.transactionDetails.yourAddress
        }
        
        configureCell(
            cell,
            isOutgoing: transaction.isOutgoing,
            partnerId: partnerId,
            partnerName: partnerName,
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
        cell.separatorInset = indexPath.row == (controller?.fetchedObjects?.count ?? 0) - 1
        ? .zero
        : UITableView.defaultTransactionsSeparatorInset
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        guard let transaction = controller?.object(at: editActionsForRowAt), let partner = transaction.partner as? CoreDataAccount, let chatroom = partner.chatroom, let transactions = chatroom.transactions  else {
            return nil
        }
        
        let messeges = transactions.first(where: { (object) -> Bool in
            return !(object is TransferTransaction)
        })
        
        let title = (messeges != nil) ? String.adamant.transactionList.toChat : String.adamant.transactionList.startChat
        
        let toChat = UITableViewRowAction(style: .normal, title: title) { _, _ in
            guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
                // TODO: Log this
                return
            }
            
            guard let account = self.accountService.account else {
                return
            }
            
            vc.hidesBottomBarWhenPushed = true
            vc.viewModel.setup(
                account: account,
                chatroom: chatroom,
                messageIdToShow: nil,
                preservationDelegate: nil
            )
            
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
        
        let title = (messeges != nil) ? String.adamant.transactionList.toChat : String.adamant.transactionList.startChat
        
        let toChat = UIContextualAction(style: .normal, title:  title, handler: { (_, _, _) in
            guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
                // TODO: Log this
                return
            }
            
            guard let account = self.accountService.account else {
                return
            }
            
            vc.hidesBottomBarWhenPushed = true
            vc.viewModel.setup(
                account: account,
                chatroom: chatroom,
                messageIdToShow: nil,
                preservationDelegate: nil
            )
            
            if let nav = self.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true)
            }
        })
        
        toChat.image = .asset(named: "chats_tab")
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
        if isBusy { return }
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if isBusy { return }
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if isBusy { return }
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
