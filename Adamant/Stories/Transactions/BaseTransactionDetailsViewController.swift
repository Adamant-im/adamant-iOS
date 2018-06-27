//
//  BaseTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import web3swift
import BigInt
import SafariServices

// MARK: - Localization
extension String.adamantLocalized {
    struct transactionDetails {
        static let title = NSLocalizedString("TransactionDetailsScene.Title", comment: "Transaction details: scene title")
        static let requestingDataProgressMessage = NSLocalizedString("TransactionDetailsScene.RequestingData", comment: "Transaction details: 'Requesting Data' progress message.")
    }
}

extension String.adamantLocalized.alert {
    static let exportUrlButton = NSLocalizedString("TransactionDetailsScene.Share.URL", comment: "Export transaction: 'Share transaction URL' button")
    static let exportSummaryButton = NSLocalizedString("TransactionDetailsScene.Share.Summary", comment: "Export transaction: 'Share transaction summary' button")
}

class BaseTransactionDetailsViewController: FormViewController {
    // MARK: - Rows
    fileprivate enum Row: Int {
        case transactionNumber = 0
        case from
        case to
        case date
        case amount
        case fee
        case confirmations
        case block
        case openInExplorer
        case openChat
        
        var tag: String {
            switch self {
            case .transactionNumber: return "id"
            case .from: return "from"
            case .to: return "to"
            case .date: return "date"
            case .amount: return "amount"
            case .fee: return "fee"
            case .confirmations: return "confirmations"
            case .block: return "block"
            case .openInExplorer: return "openInExplorer"
            case .openChat: return "openChat"
            }
        }
        
        var localized: String {
            switch self {
            case .transactionNumber: return NSLocalizedString("TransactionDetailsScene.Row.Id", comment: "Transaction details: Id row.")
            case .from: return NSLocalizedString("TransactionDetailsScene.Row.From", comment: "Transaction details: sender row.")
            case .to: return NSLocalizedString("TransactionDetailsScene.Row.To", comment: "Transaction details: recipient row.")
            case .date: return NSLocalizedString("TransactionDetailsScene.Row.Date", comment: "Transaction details: date row.")
            case .amount: return NSLocalizedString("TransactionDetailsScene.Row.Amount", comment: "Transaction details: amount row.")
            case .fee: return NSLocalizedString("TransactionDetailsScene.Row.Fee", comment: "Transaction details: fee row.")
            case .confirmations: return NSLocalizedString("TransactionDetailsScene.Row.Confirmations", comment: "Transaction details: confirmations row.")
            case .block: return NSLocalizedString("TransactionDetailsScene.Row.Block", comment: "Transaction details: Block id row.")
            case .openInExplorer: return NSLocalizedString("TransactionDetailsScene.Row.Explorer", comment: "Transaction details: 'Open transaction in explorer' row.")
            case .openChat: return ""
            }
        }
    }
    
    // MARK: - Dependencies
    var dialogService: DialogService!
    
    // MARK: - Properties
    var transaction: TransactionDetailsProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = String.adamantLocalized.transactionDetails.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
        
        // MARK: - Transfer section
        form +++ Section()
            
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.transactionNumber.tag
                $0.title = Row.transactionNumber.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.value {
                        self.shareValue(text)
                    }
                })
            
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.from.tag
                $0.title = Row.from.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.value {
                        self.shareValue(text)
                    }
                })
            
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.to.tag
                $0.title = Row.to.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                   if let text = row.value {
                        self.shareValue(text)
                    }
                })
            
            <<< DateRow() {
                $0.disabled = true
                $0.tag = Row.date.tag
                $0.title = Row.date.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = cell.detailTextLabel?.text {
                        self.shareValue(text)
                    }
                })
            
            <<< DecimalRow() {
                $0.disabled = true
                $0.tag = Row.amount.tag
                $0.title = Row.amount.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.displayValueFor?(row.value) {
                        self.shareValue(text)
                    }
                })
            
            <<< DecimalRow() {
                $0.disabled = true
                $0.tag = Row.fee.tag
                $0.title = Row.fee.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.displayValueFor?(row.value) {
                        self.shareValue(text)
                    }
                })
            
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.confirmations.tag
                $0.title = Row.confirmations.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.value {
                        self.shareValue(text)
                    }
                })
            
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.block.tag
                $0.title = Row.block.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.value {
                        self.shareValue(text)
                    }
                })
        
            <<< LabelRow() {
                $0.hidden = true
                $0.tag = Row.openInExplorer.tag
                $0.title = Row.openInExplorer.localized
                }
                .cellSetup({ (cell, _) in
                    cell.selectionStyle = .gray
                })
                .cellUpdate({ (cell, _) in
                    if let label = cell.textLabel {
                        label.font = UIFont.adamantPrimary(size: 17)
                        label.textColor = UIColor.adamantPrimary
                    }
                    
                    cell.accessoryType = .disclosureIndicator
                })
                .onCellSelection({ [weak self] (_, row) in
                    // TODO:
                    if let url = self?.transaction?.explorerUrl {
                        let safari = SFSafariViewController(url: url)
                        safari.preferredControlTintColor = UIColor.adamantPrimary
                        self?.present(safari, animated: true, completion: nil)
                    }
                })
        
            <<< LabelRow() {
                $0.hidden = true
                $0.tag = Row.openChat.tag
                $0.title = Row.openChat.localized
                }
                .cellSetup({ (cell, _) in
                    cell.selectionStyle = .gray
                })
                .cellUpdate({ (cell, _) in
                    if let label = cell.textLabel {
                        label.font = UIFont.adamantPrimary(size: 17)
                        label.textColor = UIColor.adamantPrimary
                    }
                    
                    cell.accessoryType = .disclosureIndicator
                })
                .onCellSelection({ [weak self] (_, row) in
                    self?.goToChat()
                })

        
        // MARK: - UI
        navigationAccessoryView.tintColor = UIColor.adamantPrimary
        
        guard let transaction = transaction else {
            return
        }
        
        updateDetails(with: transaction)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func set(transaction: TransactionDetailsProtocol) {
        self.transaction = transaction
        updateDetails(with: transaction)
    }
    
    private func updateDetails(with transaction: TransactionDetailsProtocol) {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .decimal
        currencyFormatter.roundingMode = .floor
        currencyFormatter.positiveFormat = "#.########"
        currencyFormatter.positiveSuffix = " \(transaction.currencyCode)"
        
        if let row: TextRow = self.form.rowBy(tag: Row.transactionNumber.tag) {
            row.value = transaction.id
            row.reload()
        }
        
        if let row: TextRow = self.form.rowBy(tag: Row.from.tag) {
            row.value = transaction.senderAddress
            row.reload()
        }
        
        if let row: TextRow = self.form.rowBy(tag: Row.to.tag) {
            row.value = transaction.recipientAddress
            row.reload()
        }
        
        if let row: DateRow = self.form.rowBy(tag: Row.date.tag) {
            row.value = transaction.sentDate
            row.reload()
        }
        
        if let row: DecimalRow = self.form.rowBy(tag: Row.amount.tag) {
            row.value = transaction.amountValue
            row.formatter = currencyFormatter
            row.reload()
        }
        
        if let row: DecimalRow = self.form.rowBy(tag: Row.fee.tag) {
            row.value = transaction.feeValue
            row.formatter = currencyFormatter
            row.reload()
        }
        
        if let row: TextRow = self.form.rowBy(tag: Row.confirmations.tag) {
            row.value = transaction.confirmationsValue
            row.reload()
        }
        
        if let row: TextRow = self.form.rowBy(tag: Row.block.tag) {
            row.value = transaction.block
            row.reload()
        }
        
        if let row: LabelRow = self.form.rowBy(tag: Row.openInExplorer.tag) {
            row.hidden = transaction.showGoToExplorer ? false : true
            row.reload()
            row.evaluateHidden()
        }
        
        if let row: LabelRow = self.form.rowBy(tag: Row.openChat.tag) {
            row.hidden = transaction.showGoToChat ? false : true
            row.title = (transaction.haveChatroom) ? String.adamantLocalized.transactionList.toChat : String.adamantLocalized.transactionList.startChat
            row.reload()
            row.evaluateHidden()
        }
    }
    
    // MARK: - Actions
    
    @objc func share(_ sender: Any) {
        guard let transaction = transaction else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
        
        if let url = transaction.explorerUrl {
            // URL
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportUrlButton, style: .default) { [weak self] _ in
                let alert = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self?.present(alert, animated: true, completion: nil)
            })
        }
        
        // Description
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportSummaryButton, style: .default, handler: { [weak self] _ in
            let text = transaction.getSummary()
            let alert = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            self?.present(alert, animated: true, completion: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func shareValue( _ value: String) {
        dialogService.presentShareAlertFor(string: value,
                                           types: [.copyToPasteboard, .share],
                                           excludedActivityTypes: nil,
                                           animated: true, completion: nil)
    }
    
    func goToChat() {
        
    }
    
    // MARK: - Privare tools
    private func updateCell(_ cell: BaseCell) {
        cell.textLabel?.textColor = UIColor.adamantPrimary
        cell.detailTextLabel?.textColor = UIColor.adamantSecondary
        
        let font = UIFont.adamantPrimary(size: 17)
        cell.textLabel?.font = font
        cell.detailTextLabel?.font = font
    }
}

class ADMTransactionDetailsViewController: BaseTransactionDetailsViewController {
    
    // MARK: - Dependencies
    var accountService: AccountService!
    var transfersProvider: TransfersProvider!
    var router: Router!
    
    // MARK: - Properties
    private let autoupdateInterval: TimeInterval = 5.0
    
    weak var timer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startUpdate()
    }
    
    deinit {
        stopUpdate()
    }
    
    override func goToChat() {
        guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
            dialogService.showError(withMessage: "TransactionDetailsViewController: Failed to get ChatViewController", error: nil)
            return
        }
        
        guard let chatroom = transaction?.chatroom else {
            dialogService.showError(withMessage: "TransactionDetailsViewController: Failed to get chatroom for transaction.", error: nil)
            return
        }
        
        guard let account = self.accountService.account else {
            dialogService.showError(withMessage: "TransactionDetailsViewController: User not logged.", error: nil)
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

extension TransferTransaction: TransactionDetailsProtocol {
    var id: String {
        return self.transactionId ?? ""
    }
    
    var senderAddress: String {
        return self.senderId ?? ""
    }
    
    var recipientAddress: String {
        return self.recipientId ?? ""
    }
    
    var amountValue: Double {
        return self.amount?.doubleValue ?? 0
    }
    
    var feeValue: Double {
        return self.fee?.doubleValue ?? 0
    }
    
    var confirmationsValue: String {
        return "\(self.confirmations)"
    }
    
    var block: String {
        return self.blockId ?? ""
    }
    
    var showGoToExplorer: Bool {
        return true
    }
    
    var explorerUrl: URL? {
        return URL(string: "https://explorer.adamant.im/tx/\(id)")
    }
    
    var showGoToChat: Bool {
        return true
    }
    
    var currencyCode: String {
        return "ADM"
    }
    
    func isOutgoing(_ address: String) -> Bool {
        return self.isOutgoing
    }
}
