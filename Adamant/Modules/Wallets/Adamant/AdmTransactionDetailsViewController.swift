//
//  AdmTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import CommonKit

final class AdmTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    
    // MARK: - Dependencies
    
    let transfersProvider: TransfersProvider
    let screensFactory: ScreensFactory
    
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
    
    override var transaction: TransactionDetails? {
        get { super.transaction }
        set { assertionFailure("Use adamant transaction") }
    }
    
    var adamantTransaction: AdamantTransactionDetails? {
        get { super.transaction as? AdamantTransactionDetails }
        set { super.transaction = newValue }
    }
    
    // MARK: - Lifecycle
    
    init(
        accountService: AccountService,
        transfersProvider: TransfersProvider,
        screensFactory: ScreensFactory,
        dialogService: DialogService,
        currencyInfo: CurrencyInfoService,
        addressBookService: AddressBookService
    ) {
        self.transfersProvider = transfersProvider
        self.screensFactory = screensFactory
        
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
        
        if showToChat,
           adamantTransaction?.chatRoom != nil,
           let section = form.sectionBy(tag: Sections.actions.tag) {
            let chatLabel = String.adamant.transactionList.toChat
            
            // MARK: Open chat
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
        
        tableView.refreshControl = refreshControl
        
        refresh(silent: true)
        
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
        guard let chatroom = adamantTransaction?.chatRoom else {
            dialogService.showError(withMessage: "AdmTransactionDetailsViewController: Failed to get chatroom for transaction.", supportEmail: true, error: nil)
            return
        }

        guard let account = accountService.account else {
            dialogService.showError(withMessage: "AdmTransactionDetailsViewController: User not logged.", supportEmail: true, error: nil)
            return
        }

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
            self.present(vc, animated: true)
        }
    }
    
    @MainActor
    @objc func refresh(silent: Bool = false) {
        refreshTask = Task {
            guard let id = transaction?.txId else {
                return
            }
            
            do {
                try await transfersProvider.refreshTransfer(id: id)
                adamantTransaction = await transfersProvider.getTransfer(id: id)
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
            self?.refresh(silent: true)
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
    }
}
