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

final class AdmTransactionsViewController: TransactionsListViewControllerBase {
    // MARK: - Dependencies
    
    let accountService: AccountService
    let transfersProvider: TransfersProvider
    let chatsProvider: ChatsProvider
    let stack: CoreDataStack
    let screensFactory: ScreensFactory
    let addressBookService: AddressBookService
    let admService: AdmWalletService
    
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
        screensFactory: ScreensFactory,
        addressBookService: AddressBookService,
        admService: AdmWalletService
    ) {
        self.accountService = accountService
        self.transfersProvider = transfersProvider
        self.chatsProvider = chatsProvider
        self.stack = stack
        self.screensFactory = screensFactory
        self.addressBookService = addressBookService
        self.admService = admService
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.dialogService = dialogService
        self.walletService = admService
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
        setupObserver()
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
            
            do {
                try controller?.performFetch()
                let transactions: [SimpleTransactionDetails] = controller?.fetchedObjects?.compactMap {
                    getTransactionDetails(by: $0)
                } ?? []
                
                update(transactions)
            } catch {
                dialogService.showError(withMessage: "Failed to get transactions. Please, report a bug", supportEmail: true, error: error)
                controller = nil
            }
            
            isBusy = false
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
            emptyLabel.isHidden = !transactions.isEmpty
            refreshControl.endRefreshing()
            stopBottomIndicator()
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
    
    func getTransactionDetails(by transaction: TransferTransaction) -> SimpleTransactionDetails {
        let partnerId = (
            transaction.isOutgoing
            ? transaction.recipientId
            : transaction.senderId
        ) ?? ""
        
        var simple = SimpleTransactionDetails(transaction)
        simple.partnerName = getPartnerName(for: partnerId)
        simple.showToChat = toShowChat(for: transaction)
        simple.comment = transaction.comment

        let partner = transaction.partner as? CoreDataAccount
        let chatroom = partner?.chatroom
        simple.chatRoom = chatroom
        return simple
    }
    
    func getPartnerName(for partnerId: String) -> String? {
        var partnerName = addressBookService.getName(for: partnerId)
        
        if let address = accountService.account?.address,
           partnerId == address {
            partnerName = String.adamant.transactionDetails.yourAddress
        }
        
        return partnerName
    }
    
    // MARK: - UITableView

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transaction = transactions[indexPath.row]
        
        let controller = screensFactory.makeAdmTransactionDetails()
        controller.transaction = transaction
        controller.comment = transaction.comment
        controller.showToChat = transaction.showToChat ?? false

        if let address = accountService.account?.address {
            let partnerName = transaction.partnerName
            
            if address == transaction.senderAddress {
                controller.senderName = String.adamant.transactionDetails.yourAddress
            } else {
                controller.senderName = partnerName
            }
            
            if address == transaction.recipientAddress {
                controller.recipientName = String.adamant.transactionDetails.yourAddress
            } else {
                controller.recipientName = partnerName
            }
        }
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let transaction = transactions[indexPath.row]
        
        guard transaction.showToChat == true,
              let chatroom = transaction.chatRoom
        else {
            return nil
        }
        
        let toChat = UIContextualAction(style: .normal, title: "") { [weak self] (_, _, _) in
            guard
                let self = self,
                let account = accountService.account
            else { return }
            
            let vc = screensFactory.makeChat()
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
                present(vc, animated: true)
            }
        }
        
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

private extension AdmTransactionsViewController {
    func setupObserver() {
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: stack.container.viewContext
        )
        .sink { [weak self] notification in
            guard let self = self else { return }
            
            let changes = notification.managedObjectContextChanges(of: TransferTransaction.self)

            if let inserted = changes.inserted, !inserted.isEmpty {
                let maped: [SimpleTransactionDetails] = inserted.map {
                    self.getTransactionDetails(by: $0)
                }
                
                var transactions = self.transactions
                transactions.append(contentsOf: maped)
                self.update(transactions)
            }
            
            if let updated = changes.updated, !updated.isEmpty {
                updated.forEach { transaction in
                    guard let index = self.transactions.firstIndex(where: {
                        $0.txId == transaction.txId
                    })
                    else { return }
                    
                    var transactions: [SimpleTransactionDetails] = self.transactions
                    transactions[index] = self.getTransactionDetails(by: transaction)
                    self.update(transactions)
                }
            }
        }
        .store(in: &subscriptions)
    }
}
