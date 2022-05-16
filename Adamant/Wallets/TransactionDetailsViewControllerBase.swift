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
        static let yourAddress = String.adamantLocalized.notifications.yourAddress
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
        case historyFiat
        case currentFiat
        
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
            case .historyFiat: return "hfiat"
            case .currentFiat: return "cfiat"
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
            case .historyFiat: return NSLocalizedString("TransactionDetailsScene.Row.HistoryFiat", comment: "Transaction details: fiat value at the time")
            case .currentFiat: return NSLocalizedString("TransactionDetailsScene.Row.CurrentFiat", comment: "Transaction details: current fiat value")
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
    var currencyInfo: CurrencyInfoService!
    
    // MARK: - Properties
    
    var transaction: TransactionDetails? = nil {
        didSet {
            if !isFiatSet {
                self.updateFiat()
            }
        }
    }
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    static let awaitingValueString = "⏱"
    
    private lazy var currencyFormatter: NumberFormatter = {
        return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
    }()

    var feeFormatter: NumberFormatter {
        return currencyFormatter
    }
    
    private lazy var fiatFormatter: NumberFormatter = {
        return AdamantBalanceFormat.fiatFormatter(for: currencyInfo.currentCurrency)
    }()
    
    private var isFiatSet = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never // some glitches, again
        }
        
        navigationItem.title = String.adamantLocalized.transactionDetails.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
        navigationOptions = RowNavigationOptions.Disabled
        
        // MARK: - Transfer section
        let detailsSection = Section(Sections.details.localized) {
            $0.tag = Sections.details.tag
        }
            
        // MARK: Transaction number
        let idRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.transactionNumber.tag
            $0.title = Rows.transactionNumber.localized
            
            if let value = transaction?.txId {
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
            
            if let value = self?.transaction?.txId {
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
                if transaction.senderAddress.count == 0 {
                    $0.value = DoubleDetail(first: TransactionDetailsViewControllerBase.awaitingValueString, second: nil)
                } else if let senderName = self?.senderName {
                    $0.value = DoubleDetail(first: senderName, second: transaction.senderAddress)
                } else {
                    $0.value = DoubleDetail(first: transaction.senderAddress, second: nil)
                }
            } else {
                $0.value = nil
            }
            
            let height = self?.senderName != nil ? DoubleDetailsTableViewCell.fullHeight : DoubleDetailsTableViewCell.compactHeight
            $0.cell.height = { height }
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            guard let value = row.value else {
                return
            }
            
            let text: String
            if let address = value.second {
                text = address
            } else {
                text = value.first
            }
            
            self?.shareValue(text, from: cell)
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let transaction = self?.transaction {
                if transaction.senderAddress.count == 0 {
                    row.value = DoubleDetail(first: TransactionDetailsViewControllerBase.awaitingValueString, second: nil)
                } else if let senderName = self?.senderName {
                    row.value = DoubleDetail(first: senderName, second: transaction.senderAddress)
                } else {
                    row.value = DoubleDetail(first: transaction.senderAddress, second: nil)
                }
            } else {
                row.value = nil
            }
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
            
            let height = self?.recipientName != nil ? DoubleDetailsTableViewCell.fullHeight : DoubleDetailsTableViewCell.compactHeight
            $0.cell.height = { height }
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            guard let value = row.value else {
                return
            }
            
            let text: String
            if let address = value.second {
                text = address
            } else {
                text = value.first
            }
            
            self?.shareValue(text, from: cell)
        }.cellUpdate { (cell, _) in
            cell.textLabel?.textColor = .black
        }
        
        detailsSection.append(recipientRow)
        
        // MARK: Date
        let dateRow = LabelRow() { [weak self] in
            $0.disabled = true
            $0.tag = Rows.date.tag
            $0.title = Rows.date.localized
            
            if let raw = transaction?.dateValue, let value = self?.dateFormatter.string(from: raw) {
                $0.value = value
            } else {
                $0.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let value = self?.transaction?.dateValue {
                let text = value.humanizedDateTimeFull()
                self?.shareValue(text, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let raw = self?.transaction?.dateValue, let value = self?.dateFormatter.string(from: raw) {
                row.value = value
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
            
        detailsSection.append(dateRow)
        
        // MARK: Amount
        let amountRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.amount.tag
            $0.title = Rows.amount.localized
            if let value = transaction?.amountValue {
                $0.value = currencyFormatter.string(from: value)
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
            
            if let value = self?.transaction?.amountValue, let formatter = self?.currencyFormatter {
                row.value = formatter.string(from: value)
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
            
        detailsSection.append(amountRow)
        
        // MARK: Fee
        let feeRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.fee.tag
            $0.title = Rows.fee.localized
            
            if let value = transaction?.feeValue {
                $0.value = feeFormatter.string(from: value)
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
            
            if let value = self?.transaction?.feeValue, let formatter = self?.feeFormatter {
                row.value = formatter.string(from: value)
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
            
            if let value = transaction?.blockValue,
               !value.isEmpty {
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
            
            if let value = self?.transaction?.blockValue,
               !value.isEmpty {
                row.value = value
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
            
        detailsSection.append(blockRow)
            
        // MARK: Status
        let statusRow = LabelRow() {
            $0.tag = Rows.status.tag
            $0.title = Rows.status.localized
            $0.value = transaction?.transactionStatus?.localized
            
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                return self?.transaction?.transactionStatus == nil
            })
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
        
        // MARK: Current Fiat
        let currentFiatRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.currentFiat.tag
            $0.title = Rows.currentFiat.localized
            
            if let amount = transaction?.amountValue, let symbol = currencySymbol, let rate = currencyInfo.getRate(for: symbol) {
                let value = amount * rate
                $0.value = fiatFormatter.string(from: value)
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
            
            if let amount = self?.transaction?.amountValue,
               let symbol = self?.currencySymbol,
               let rate = self?.currencyInfo.getRate(for: symbol),
               let value = self?.fiatFormatter.string(from: amount * rate) {
                row.value = value
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
        
        detailsSection.append(currentFiatRow)
        
        form.append(detailsSection)
        
        // MARK: History Fiat
        let fiatRow = LabelRow() {
            $0.disabled = true
            $0.tag = Rows.historyFiat.tag
            $0.title = Rows.historyFiat.localized
            
            $0.value = TransactionDetailsViewControllerBase.awaitingValueString
            }.cellSetup { (cell, _) in
                cell.selectionStyle = .gray
            }.onCellSelection { [weak self] (cell, row) in
                if let text = row.value {
                    self?.shareValue(text, from: cell)
                }
            }.cellUpdate { (cell, _) in
                cell.textLabel?.textColor = .black
        }
        
        detailsSection.append(fiatRow)
        
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
                cell.textView?.backgroundColor = UIColor.clear
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
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                return self?.transaction == nil
            })
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
            
            if #available(iOS 13.0, *) {
                let safari = SFSafariViewController(url: url)
                safari.preferredControlTintColor = UIColor.adamant.primary
                safari.modalPresentationStyle = .overFullScreen
                self?.present(safari, animated: true, completion: nil)
            } else {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
        actionsSection.append(explorerRow)
        
        form.append(actionsSection)
        
        // Get fiat value
        self.updateFiat()
    }
    
    func updateFiat() {
        if let date = transaction?.dateValue, let currencySymbol = currencySymbol, let amount = transaction?.amountValue {
            self.isFiatSet = true
            let currentFiat = currencyInfo.currentCurrency.rawValue
            currencyInfo.getHistory(for: currencySymbol, timestamp: date) { [weak self] (result) in
                switch result {
                case .success(let tickers):
                    self?.isFiatSet = true
                    guard let tickers = tickers, let ticker = tickers["\(currencySymbol)/\(currentFiat)"] else {
                        break
                    }
                    
                    let totalFiat = amount * ticker
                    let fiatString = self?.fiatFormatter.string(from: totalFiat)
                    
                    if let row: LabelRow = self?.form.rowBy(tag: Rows.historyFiat.tag) {
                        DispatchQueue.main.async {
                            row.value = fiatString
                            row.updateCell()
                        }
                    }
                    
                case .failure:
                    self?.isFiatSet = false
                    break
                }
            }
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
                alert.modalPresentationStyle = .overFullScreen
                self?.present(alert, animated: true, completion: nil)
            })
        }

        // Description
        if let summary = summary(for: transaction) {
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportSummaryButton, style: .default) { [weak self] _ in
                let text = summary
                let alert = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                alert.modalPresentationStyle = .overFullScreen
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
        return transaction.summary(with: explorerUrl(for: transaction)?.absoluteString)
    }
}
