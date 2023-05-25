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
    
    let transfersProvider: TransfersProvider
    let router: Router
    
    // MARK: - Properties
    private let autoupdateInterval: TimeInterval = 5.0
    
    var showToChat: Bool = false
    
    weak var timer: Timer?
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = .adamant.primary
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return control
    }()
    
    // MARK: - Lifecycle
    
    init(
        accountService: AccountService,
        transfersProvider: TransfersProvider,
        router: Router,
        dialogService: DialogService,
        currencyInfo: CurrencyInfoService,
        addressBookService: AddressBookService
    ) {
        self.transfersProvider = transfersProvider
        self.router = router
        
        super.init(
            dialogService: dialogService,
            currencyInfo: currencyInfo,
            addressBookService: addressBookService,
            accountService:  accountService
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        currencySymbol = AdmWalletService.currencySymbol
        
        super.viewDidLoad()
        
        if showToChat {
            let haveChatroom: Bool
            
            if let transfer = transaction as? TransferTransaction, let partner = transfer.partner as? CoreDataAccount, let chatroom = partner.chatroom, let transactions = chatroom.transactions {
                let messeges = transactions.first(where: { (object) -> Bool in
                    return !(object is TransferTransaction)
                })
                
                haveChatroom = messeges != nil
            } else {
                haveChatroom = false
            }
            
            let chatLabel = haveChatroom ? String.adamantLocalized.transactionList.toChat : String.adamantLocalized.transactionList.startChat
            
            // MARK: Open chat
            if let trs = transaction as? TransferTransaction, trs.chatroom != nil, let section = form.sectionBy(tag: Sections.actions.tag) {
                let row = LabelRow {
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
        }
        
        tableView.refreshControl = refreshControl
        
        refresh(true)
        
        startUpdate()
    }
    
    deinit {
        stopUpdate()
    }
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        let id = transaction.txId
        
        return URL(string: "\(AdmWalletService.explorerAddress)\(id)")
    }
    
    func goToChat() {
        guard let transfer = transaction as? TransferTransaction else {
            return
        }
        
        guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
            dialogService.showError(withMessage: "AdmTransactionDetailsViewController: Failed to get ChatViewController", supportEmail: true, error: nil)
            return
        }

        guard let chatroom = transfer.chatroom else {
            dialogService.showError(withMessage: "AdmTransactionDetailsViewController: Failed to get chatroom for transaction.", supportEmail: true, error: nil)
            return
        }

        guard let account = accountService.account else {
            dialogService.showError(withMessage: "AdmTransactionDetailsViewController: User not logged.", supportEmail: true, error: nil)
            return
        }

        vc.hidesBottomBarWhenPushed = true
        vc.viewModel.setup(
            account: account,
            chatroom: chatroom,
            messageToShow: nil,
            preservationDelegate: nil
        )

        if let nav = self.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true)
        }
    }
    
    @MainActor
    @objc func refresh(_ silent: Bool = false) {
        refreshTask = Task {
            guard let id = transaction?.txId else {
                return
            }
            
            do {
                try await transfersProvider.refreshTransfer(id: id)
                refreshControl.endRefreshing()
                tableView.reloadData()
            } catch {
                refreshControl.endRefreshing()
                guard !silent else { return }
                dialogService.showRichError(error: error)
            }
        }
    }
    
    // MARK: - Autoupdate
    
    func startUpdate() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: autoupdateInterval, repeats: true) { [weak self] _ in
            self?.refresh(true)
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
    }
}
