//
//  DelegateDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 09/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import SafariServices

class DelegateDetailsViewController: FormViewController {
    
    // MARK: - Rows
    fileprivate enum Row: Int {
        case username = 0
        case address
        case publicKey
        case vote
        case producedblocks
        case missedblocks
        case rate
        case rank
        case approval
        case productivity
        case forgetingTime
        case forged
        case openInExplorer
        
        var tag: String {
            switch self {
            case .username:
                return "username"
            case .address:
                return "address"
            case .publicKey:
                return "publicKey"
            case .vote:
                return "vote"
            case .producedblocks:
                return "producedblocks"
            case .missedblocks:
                return "missedblocks"
            case .rate:
                return "rate"
            case .rank:
                return "rank"
            case .approval:
                return "approval"
            case .productivity:
                return "productivity"
            case .forgetingTime:
                return "forgetingTime"
            case .forged:
                return "forged"
                
            case .openInExplorer: return "openInExplorer"

                
            default:
                return ""
            }
        }
        
        var localized: String {
            switch self {
            case .username:
                return NSLocalizedString("Delegates.Row.Username", comment: "Delegate Details Screen: Rows title for 'Username'")
            case .address:
                return NSLocalizedString("Delegates.Row.Address", comment: "Delegate Details Screen: Rows title for 'Address'")
            case .publicKey:
                return NSLocalizedString("Delegates.Row.PublicKey", comment: "Delegate Details Screen: Rows title for 'Public Key'")
            case .vote:
                return NSLocalizedString("Delegates.Row.VoteWeight", comment: "Delegate Details Screen: Rows title for 'Vote weight'")
            case .producedblocks:
                return NSLocalizedString("Delegates.Row.ProducedBlocks", comment: "Delegate Details Screen: Rows title for 'Produced blocks'")
            case .missedblocks:
                return NSLocalizedString("Delegates.Row.MissedBlocks", comment: "Delegate Details Screen: Rows title for 'Missed blocks'")
            case .rate:
                return NSLocalizedString("Delegates.Row.Rate", comment: "Delegate Details Screen: Rows title for 'Rate'")
            case .rank:
                return NSLocalizedString("Delegates.Row.Rank", comment: "Delegate Details Screen: Rows title for 'Rank'")
            case .approval:
                return NSLocalizedString("Delegates.Row.Approval", comment: "Delegate Details Screen: Rows title for 'Approval'")
            case .productivity:
                return NSLocalizedString("Delegates.Row.Productivity", comment: "Delegate Details Screen: Rows title for 'Productivity'")
            case .forgetingTime:
                return NSLocalizedString("Delegates.Row.ForgetingTime", comment: "Delegate Details Screen: Rows title for 'Forgeting time'")
            case .forged:
                return NSLocalizedString("Delegates.Row.Forged", comment: "Delegate Details Screen: Rows title for 'Forged'")
                
            case .openInExplorer: return NSLocalizedString("TransactionDetailsScene.Row.Explorer", comment: "Transaction details: 'Open transaction in explorer' row.")
                
                
            default:
                return ""
            }
        }
    }
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    
    // MARK: - Properties
    var delegate: Delegate?
    
    private let autoupdateInterval: TimeInterval = 5.0
    
    weak var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        navigationItem.title = String.adamantLocalized.transactionDetails.title
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .floor
        formatter.positiveFormat = "#.##"
        formatter.positiveSuffix = "%"
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .decimal
        currencyFormatter.roundingMode = .floor
        currencyFormatter.positiveFormat = "#.########"
        currencyFormatter.positiveSuffix = " \(AdamantUtilities.currencyCode)"
        
        form +++ Section()
            
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.username.tag
                $0.title = Row.username.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.value {
                        self.shareValue(text)
                    }
                })
        
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.address.tag
                $0.title = Row.address.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.value {
                        self.shareValue(text)
                    }
                })
        
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.publicKey.tag
                $0.title = Row.publicKey.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.value {
                        self.shareValue(text)
                    }
                })
        
            <<< DecimalRow() {
                $0.disabled = true
                $0.tag = Row.vote.tag
                $0.title = Row.vote.localized
                $0.formatter = currencyFormatter
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
        
            <<< IntRow() {
                $0.disabled = true
                $0.tag = Row.producedblocks.tag
                $0.title = Row.producedblocks.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
        
            <<< IntRow() {
                $0.disabled = true
                $0.tag = Row.missedblocks.tag
                $0.title = Row.missedblocks.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
        
            <<< IntRow() {
                $0.disabled = true
                $0.tag = Row.rate.tag
                $0.title = Row.rate.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
        
            <<< IntRow() {
                $0.disabled = true
                $0.tag = Row.rank.tag
                $0.title = Row.rank.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
        
            <<< DecimalRow() {
                $0.disabled = true
                $0.tag = Row.approval.tag
                $0.title = Row.approval.localized
                $0.formatter = formatter
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
        
            <<< DecimalRow() {
                $0.disabled = true
                $0.tag = Row.productivity.tag
                $0.title = Row.productivity.localized
                $0.formatter = formatter
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
            
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.forgetingTime.tag
                $0.title = Row.forgetingTime.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
            
            <<< DecimalRow() {
                $0.disabled = true
                $0.tag = Row.forged.tag
                $0.title = Row.forged.localized
                $0.formatter = currencyFormatter
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }
        
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
                        label.font = UIFont.adamantPrimary(ofSize: 17)
                        label.textColor = UIColor.adamantPrimary
                    }
                    
                    cell.accessoryType = .disclosureIndicator
                })
                .onCellSelection({ [weak self] (_, row) in
                    if let address = self?.delegate?.address, let url = URL(string: "https://explorer.adamant.im/delegate/\(address)") {
                        let safari = SFSafariViewController(url: url)
                        safari.preferredControlTintColor = UIColor.adamantPrimary
                        self?.present(safari, animated: true, completion: nil)
                    }
                })
        
        if let delegate = delegate {
            updateDetails(with: delegate)
        }
    }
    
    private func updateDetails(with delegate: Delegate) {

        if let row: TextRow = self.form.rowBy(tag: Row.username.tag) {
            row.value = delegate.username
            row.reload()
        }

        if let row: TextRow = self.form.rowBy(tag: Row.address.tag) {
            row.value = delegate.address
            row.reload()
        }

        if let row: TextRow = self.form.rowBy(tag: Row.publicKey.tag) {
            row.value = delegate.publicKey
            row.reload()
        }
        
        if let row: DecimalRow = self.form.rowBy(tag: Row.vote.tag) {
            let votesWeight = Decimal(string: delegate.vote) ?? 0
            row.value = (votesWeight.shiftedFromAdamant() as NSDecimalNumber).doubleValue
            row.reload()
        }
        
        if let row: IntRow = self.form.rowBy(tag: Row.producedblocks.tag) {
            row.value = delegate.producedblocks
            row.reload()
        }
        
        if let row: IntRow = self.form.rowBy(tag: Row.missedblocks.tag) {
            row.value = delegate.missedblocks
            row.reload()
        }
        
        if let row: IntRow = self.form.rowBy(tag: Row.rate.tag) {
            row.value = delegate.rate
            row.reload()
        }
        
        if let row: IntRow = self.form.rowBy(tag: Row.rank.tag) {
            row.value = delegate.rank
            row.reload()
        }

        if let row: DecimalRow = self.form.rowBy(tag: Row.approval.tag) {
            row.value = delegate.approval
            row.reload()
        }
        
        if let row: DecimalRow = self.form.rowBy(tag: Row.productivity.tag) {
            row.value = delegate.productivity
            row.reload()
        }
        
        if let row: LabelRow = self.form.rowBy(tag: Row.openInExplorer.tag) {
            row.hidden = false
            row.evaluateHidden()
        }
        
        self.apiService.getForgedByAccount(publicKey: delegate.publicKey) { (result) in
            switch result {
            case .success(let details):
                print(details)
                
                DispatchQueue.main.async {
                    if let row: DecimalRow = self.form.rowBy(tag: Row.forged.tag) {
                        row.value = (details.forged as NSDecimalNumber).doubleValue
                        row.reload()
                    }
                }
            case .failure(let error):
                print(error)
                self.dialogService.showError(withMessage: error.localized, error: error)
            }
        }
        
        self.apiService.getForgingTime(for: delegate) { result in
            switch result {
            case .success(let seconds):
                print(seconds)
                if let row: TextRow = self.form.rowBy(tag: Row.forgetingTime.tag) {
                    if seconds < 0 {
                        row.value = "..."
                    } else if seconds == 0 {
                        row.value = String.adamantLocalized.delegates.now
                    } else {
                        let minutes = floor(Double(seconds) / 60)
                        let seconds = Double(seconds) - (minutes * 60)
                        if minutes > 0 && seconds > 0 {
                            row.value = "\(Int(minutes)) \(String.adamantLocalized.delegates.unitMinutes) \(Int(seconds)) \(String.adamantLocalized.delegates.unitSeconds)"
                        } else if minutes > 0 {
                            row.value = "\(Int(minutes)) \(String.adamantLocalized.delegates.unitMinutes)"
                        } else {
                            row.value = "\(Int(seconds)) \(String.adamantLocalized.delegates.unitSeconds)"
                        }
                    }
                    
                    DispatchQueue.main.async {
                        row.reload()
                    }
                }
                
            case .failure(let error):
                print(error)
                self.dialogService.showError(withMessage: error.localized, error: error)
            }
        }
    }
    
    // MARK: - Privare tools
    private func updateCell(_ cell: BaseCell) {
        cell.textLabel?.textColor = UIColor.adamantPrimary
        cell.detailTextLabel?.textColor = UIColor.adamantSecondary
        
        let font = UIFont.adamantPrimary(ofSize: 17)
        cell.textLabel?.font = font
        cell.detailTextLabel?.font = font
    }
    
    private func shareValue( _ value: String) {
        dialogService.presentShareAlertFor(string: value,
                                           types: [.copyToPasteboard, .share],
                                           excludedActivityTypes: nil,
                                           animated: true, completion: nil)
    }
}
