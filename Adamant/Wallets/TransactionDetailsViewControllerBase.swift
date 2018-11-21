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
        case status
        case openInExplorer
        case openChat
        case comment
        
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
            case .status: return "status"
            case .openInExplorer: return "openInExplorer"
            case .openChat: return "openChat"
            case .comment: return "comment"
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
            case .status: return NSLocalizedString("TransactionDetailsScene.Row.Status", comment: "Transaction details: Transaction delivery status.")
            case .openInExplorer: return NSLocalizedString("TransactionDetailsScene.Row.Explorer", comment: "Transaction details: 'Open transaction in explorer' row.")
            case .openChat: return ""
            case .comment: return ""
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
    
    enum Sections {
        case details
        case comment
        case actions
        
        var localized: String {
            switch self {
            case .details: return ""
            case .comment: return NSLocalizedString("TransactionDetailsScene.Section.Comment", comment: "Transaction details: 'Comments' section")
            case .actions: return NSLocalizedString("TransactionDetailsScene.Section.Actions", comment: "Transaction details: 'Actions' section")
            }
        }
        
        var tag: String {
            switch self {
            case .details: return "details"
            case .comment: return "comment"
            case .actions: return "actions"
            }
        }
    }
    
    // MARK: - Dependencies
    var dialogService: DialogService!
    
    // MARK: - Properties
    
    var transaction: TransactionDetails? = nil
    
    private static let awaitingValueString = "⏱"
    
    private lazy var currencyFormatter: NumberFormatter = {
        return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
    }()
    
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
        let detailsSection = Section(Sections.details.localized) {
            $0.tag = Sections.details.tag
        }
            
        // MARK: Transaction number
        let idRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.transactionNumber.tag
            $0.title = Rows.transactionNumber.localized
            
            if let value = transaction?.id {
                $0.value = value
            } else {
                $0.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let text = row.value {
                self?.shareValue(text, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let value = self?.transaction?.id {
                row.value = value
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
        
        detailsSection.append(idRow)
        
        // MARK: Sender
        let senderRow = DoubleDetailsRow() { [weak self] in
            $0.disabled = true
            $0.tag = Rows.from.tag
            $0.cell.titleLabel.text = Rows.from.localized
            
            if let transaction = transaction {
                if let senderName = self?.senderName {
                    $0.value = DoubleDetail(first: senderName, second: transaction.senderAddress)
                } else {
                    $0.value = DoubleDetail(first: transaction.senderAddress, second: nil)
                }
            } else {
                $0.value = nil
            }
        }.cellSetup { [weak self] (cell, _) in
            cell.selectionStyle = .gray
            cell.height = {
                if self?.senderName != nil {
                    return DoubleDetailsTableViewCell.fullHeight
                } else {
                    return DoubleDetailsTableViewCell.compactHeight
                }
            }
        }.onCellSelection { [weak self] (cell, row) in
            guard let value = row.value else {
                return
            }
            
            let text: String
            if let name = value.second {
                text = "\(name) (\(value.first))"
            } else {
                text = value.first
            }
            
            self?.shareValue(text, from: cell)
        }.cellUpdate { (cell, _) in
            cell.textLabel?.textColor = .black
        }
            
        detailsSection.append(senderRow)
        
        // MARK: Recipient
        let recipientRow = DoubleDetailsRow() { [weak self] in
            $0.disabled = true
            $0.tag = Rows.to.tag
            $0.cell.titleLabel.text = Rows.to.localized
            
            if let transaction = transaction {
                if let recipientName = self?.recipientName {
                    $0.value = DoubleDetail(first: recipientName, second: transaction.recipientAddress)
                } else {
                    $0.value = DoubleDetail(first: transaction.recipientAddress, second: nil)
                }
            } else {
                $0.value = nil
            }
        }.cellSetup { [weak self] (cell, _) in
            cell.selectionStyle = .gray
            cell.height = {
                if self?.recipientName != nil {
                    return DoubleDetailsTableViewCell.fullHeight
                } else {
                    return DoubleDetailsTableViewCell.compactHeight
                }
            }
        }.onCellSelection { [weak self] (cell, row) in
            guard let value = row.value else {
                return
            }
            
            let text: String
            if let name = value.second {
                text = "\(name) (\(value.first))"
            } else {
                text = value.first
            }
            
            self?.shareValue(text, from: cell)
        }.cellUpdate { (cell, _) in
            cell.textLabel?.textColor = .black
        }
        
        detailsSection.append(recipientRow)
        
        // MARK: Date
        let dateRow = DateTimeRow() {
            $0.disabled = true
            $0.tag = Rows.date.tag
            $0.title = Rows.date.localized
            $0.value = transaction?.dateValue
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            $0.dateFormatter = dateFormatter
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let value = row.value {
                let text = value.humanizedDateTimeFull()
                self?.shareValue(text, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            row.value = self?.transaction?.dateValue
        }
            
        detailsSection.append(dateRow)
        
        // MARK: Amount
        let amountRow = DecimalRow() {
            $0.disabled = true
            $0.tag = Rows.amount.tag
            $0.title = Rows.amount.localized
            $0.formatter = AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
            $0.value = transaction?.amountValue.doubleValue
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let value = row.value {
                let text = AdamantBalanceFormat.full.format(value, withCurrencySymbol: self?.currencySymbol ?? nil)
                self?.shareValue(text, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            row.value = self?.transaction?.amountValue.doubleValue
        }
            
        detailsSection.append(amountRow)
        
        // MARK: Fee
        let feeRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.fee.tag
            $0.title = Rows.fee.localized
            
            if let value = transaction?.feeValue {
                $0.value = currencyFormatter.string(fromDecimal: value)
            } else {
                $0.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let value = row.value {
                self?.shareValue(value, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let value = self?.transaction?.feeValue, let formatter = self?.currencyFormatter {
                row.value = formatter.string(fromDecimal: value)
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
            
        detailsSection.append(feeRow)
        
        // MARK: Confirmations
        let confirmationsRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.confirmations.tag
            $0.title = Rows.confirmations.localized
            
            if let value = transaction?.confirmationsValue, value != "0" {
                $0.value = value
            } else {
                $0.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let text = row.value {
                self?.shareValue(text, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let value = self?.transaction?.confirmationsValue, value != "0" {
                row.value = value
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
            
        detailsSection.append(confirmationsRow)
        
        // MARK: Block
        let blockRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.block.tag
            $0.title = Rows.block.localized
            
            if let value = transaction?.blockValue {
                $0.value = value
            } else {
                $0.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let text = row.value {
                self?.shareValue(text, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let value = self?.transaction?.blockValue {
                row.value = value
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
            
        detailsSection.append(blockRow)
            
        // MARK: Status
        if let status = transaction?.transactionStatus {
            let statusRow = LabelRow() {
                $0.tag = Rows.status.tag
                $0.title = Rows.status.localized
                $0.value = status.localized
            }.cellSetup { (cell, _) in
                cell.selectionStyle = .gray
            }.onCellSelection { [weak self] (cell, row) in
                if let text = row.value {
                    self?.shareValue(text, from: cell)
                }
            }.cellUpdate { [weak self] (cell, row) in
                cell.textLabel?.textColor = .black
                
                row.value = self?.transaction?.transactionStatus?.localized
            }
            
            detailsSection.append(statusRow)
        }
        
        form.append(detailsSection)
        
        // MARK: Comments section
        
        if let comment = comment {
            let commentSection = Section(Sections.comment.localized) {
                $0.tag = Sections.comment.tag
            }
            
            let row = TextAreaRow(Rows.comment.tag) {
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
                $0.value = comment
            }.cellSetup { (cell, _) in
                cell.selectionStyle = .gray
            }.cellUpdate { (cell, _) in
                cell.textView.isSelectable = false
                cell.textView.isEditable = false
            }.onCellSelection { [weak self] (cell, row) in
                if let text = row.value {
                    self?.shareValue(text, from: cell)
                }
            }
            
            commentSection.append(row)
            
            form.append(commentSection)
        }
            
        // MARK: Actions section
        
        let actionsSection = Section(Sections.actions.localized) {
            $0.tag = Sections.actions.tag
        }
            
        // MARK: Open in explorer
        let explorerRow = LabelRow(Rows.openInExplorer.tag) {
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                if let transaction = self?.transaction {
                    return self?.explorerUrl(for: transaction) == nil
                } else {
                    return true
                }
            })
            
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
        
        actionsSection.append(explorerRow)
        
        form.append(actionsSection)
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
    
    func shareValue(_ value: String, from: UIView) {
        dialogService.presentShareAlertFor(string: value, types: [.copyToPasteboard, .share], excludedActivityTypes: nil, animated: true, from: from) { [weak self] in
            guard let tableView = self?.tableView else {
                return
            }
            
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - To override
    
    var currencySymbol: String? = nil
    
    // MARK: - Fix this later
    var senderName: String? = nil
    var recipientName: String? = nil
    var comment: String? = nil
    
    func explorerUrl(for transaction: TransactionDetails) -> URL? {
        return nil
    }
    
    func summary(for transaction: TransactionDetails) -> String? {
        return AdamantFormattingTools.summaryFor(transaction: transaction, url: explorerUrl(for: transaction))
    }
}
