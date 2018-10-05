//
//  TransactionDetailsViewControllerBase.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import SafariServices

// MARK: - Localization
extension String.adamantLocalized {
    struct transactionDetails {
        static let title = NSLocalizedString("TransactionDetailsScene.Title", comment: "Transaction details: scene title")
        static let yourAddress = NSLocalizedString("TransactionDetailsScene.YourAddress", comment: "Transaction details: 'Your address' flag.")
        static let requestingDataProgressMessage = NSLocalizedString("TransactionDetailsScene.RequestingData", comment: "Transaction details: 'Requesting Data' progress message.")
    }
}

extension String.adamantLocalized.alert {
    static let exportUrlButton = NSLocalizedString("TransactionDetailsScene.Share.URL", comment: "Export transaction: 'Share transaction URL' button")
    static let exportSummaryButton = NSLocalizedString("TransactionDetailsScene.Share.Summary", comment: "Export transaction: 'Share transaction summary' button")
}

class TransactionDetailsViewControllerBase: FormViewController {
    // MARK: - Rows
    enum Rows {
        case transactionNumber
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
        
        var image: UIImage? {
            switch self {
            case .openInExplorer: return #imageLiteral(resourceName: "row_explorer")
            case .openChat: return #imageLiteral(resourceName: "row_chat")
                
            default: return nil
            }
        }
    }
    
    // MARK: - Dependencies
    var dialogService: DialogService!
    
    // MARK: - Properties
    
    var transaction: TransactionDetails? = nil {
        didSet {
            tableView?.reloadData()
        }
    }
    
    private let cellIdentifier = "cell"
    private let doubleDetailsCellIdentifier = "dcell"
    private let defaultCellHeight: CGFloat = 50.0
    
    var showToChatRow = true
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        navigationItem.title = String.adamantLocalized.transactionDetails.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
        navigationAccessoryView.tintColor = UIColor.adamant.primary
        
        // MARK: - Transfer section
        form +++ Section()
            
        // MARK: Transaction number
        <<< TextRow() {
            $0.disabled = true
            $0.tag = Rows.transactionNumber.tag
            $0.title = Rows.transactionNumber.localized
            $0.value = transaction?.id
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { (_, row) in
            if let text = row.value {
                self.shareValue(text)
            }
        }
        
        // MARK: Sender
        <<< TextRow() {
            $0.disabled = true
            $0.tag = Rows.from.tag
            $0.title = Rows.from.localized
            $0.value = transaction?.senderAddress
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { (_, row) in
            if let text = row.value {
                self.shareValue(text)
            }
        }
        
        // MARK: Recipient
        <<< TextRow() {
            $0.disabled = true
            $0.tag = Rows.to.tag
            $0.title = Rows.to.localized
            $0.value = transaction?.recipientAddress
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { (_, row) in
           if let text = row.value {
                self.shareValue(text)
            }
        }
        
        // MARK: Date
        <<< DateRow() {
            $0.disabled = true
            $0.tag = Rows.date.tag
            $0.title = Rows.date.localized
            $0.value = transaction?.dateValue
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (_, row) in
            if let value = row.value {
                let text = value.humanizedDateTimeFull()
                self?.shareValue(text)
            }
        }
        
        // MARK: Amount
        <<< DecimalRow() {
            $0.disabled = true
            $0.tag = Rows.amount.tag
            $0.title = Rows.amount.localized
            $0.formatter = AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
            $0.value = transaction?.amountValue.doubleValue
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (_, row) in
            if let value = row.value {
                let text = AdamantBalanceFormat.full.format(value, withCurrencySymbol: self?.currencySymbol ?? nil)
                self?.shareValue(text)
            }
        }
        
        // MARK: Fee
        <<< DecimalRow() {
            $0.disabled = true
            $0.tag = Rows.fee.tag
            $0.title = Rows.fee.localized
            $0.formatter = AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
            $0.value = transaction?.feeValue.doubleValue
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (_, row) in
            if let value = row.value {
                let text = AdamantBalanceFormat.full.format(value, withCurrencySymbol: self?.currencySymbol ?? nil)
                self?.shareValue(text)
            }
        }
        
        // MARK: Confirmations
        <<< TextRow() {
            $0.disabled = true
            $0.tag = Rows.confirmations.tag
            $0.title = Rows.confirmations.localized
            $0.value = transaction?.confirmationsValue
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (_, row) in
            if let text = row.value {
                self?.shareValue(text)
            }
        }
        
        // MARK: Block
        <<< TextRow() {
            $0.disabled = true
            $0.tag = Rows.block.tag
            $0.title = Rows.block.localized
            $0.value = transaction?.blockValue
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (_, row) in
            if let text = row.value {
                self?.shareValue(text)
            }
        }
    
        // MARK: Open in explorer
        <<< LabelRow() {
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                if let transaction = self?.transaction {
                    return self?.explorerUrl(for: transaction) == nil
                } else {
                    return true
                }
            })
            
            $0.tag = Rows.openInExplorer.tag
            $0.title = Rows.openInExplorer.localized
            $0.cell.imageView?.image = Rows.openInExplorer.image
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let transaction = self?.transaction, let url = self?.explorerUrl(for: transaction) else {
                return
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            self?.present(safari, animated: true, completion: nil)
        }
    }
    
    // MARK: - Actions
    
    @objc func share(_ sender: Any) {
        guard let transaction = transaction else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
        
        if let url = explorerUrl(for: transaction) {
            // URL
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportUrlButton, style: .default) { [weak self] _ in
                let alert = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self?.present(alert, animated: true, completion: nil)
            })
        }

        // Description
        if let summary = summary(for: transaction) {
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportSummaryButton, style: .default) { [weak self] _ in
                let text = summary
                let alert = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                self?.present(alert, animated: true, completion: nil)
            })
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Tools
    
    func shareValue(_ value: String) {
        dialogService.presentShareAlertFor(string: value, types: [.copyToPasteboard, .share], excludedActivityTypes: nil, animated: true) { [weak self] in
            guard let tableView = self?.tableView else {
                return
            }
            
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - To override
    
    var currencySymbol: String = ""
    
    func explorerUrl(for transaction: TransactionDetails) -> URL? {
        return nil
    }
    
    func summary(for transaction: TransactionDetails) -> String? {
        return AdamantFormattingTools.summaryFor(transaction: transaction, url: explorerUrl(for: transaction))
    }
}
