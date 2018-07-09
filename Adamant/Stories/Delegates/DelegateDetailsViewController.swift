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
                
            case .openInExplorer: return "openInExplorer"

                
            default:
                return ""
            }
        }
        
        var localized: String {
            switch self {
            case .username:
                return "Username"
            case .address:
                return "Address"
            case .publicKey:
                return "Public Key"
            case .vote:
                return "Vote"
            case .producedblocks:
                return "Produced blocks"
            case .missedblocks:
                return "Missed blocks"
            case .rate:
                return "Rate"
            case .rank:
                return "Rank"
            case .approval:
                return "Approval"
            case .productivity:
                return "Productivity"
                
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
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .floor
        formatter.positiveFormat = "#.##"
        formatter.positiveSuffix = "%"
        
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
        
            <<< TextRow() {
                $0.disabled = true
                $0.tag = Row.vote.tag
                $0.title = Row.vote.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.value {
                        self.shareValue(text)
                    }
                })
        
            <<< IntRow() {
                $0.disabled = true
                $0.tag = Row.producedblocks.tag
                $0.title = Row.producedblocks.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.displayValueFor?(row.value) {
                        self.shareValue(text)
                    }
                })
        
            <<< IntRow() {
                $0.disabled = true
                $0.tag = Row.missedblocks.tag
                $0.title = Row.missedblocks.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.displayValueFor?(row.value) {
                        self.shareValue(text)
                    }
                })
        
            <<< IntRow() {
                $0.disabled = true
                $0.tag = Row.rate.tag
                $0.title = Row.rate.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.displayValueFor?(row.value) {
                        self.shareValue(text)
                    }
                })
        
            <<< IntRow() {
                $0.disabled = true
                $0.tag = Row.rank.tag
                $0.title = Row.rank.localized
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.displayValueFor?(row.value) {
                        self.shareValue(text)
                    }
                })
        
            <<< DecimalRow() {
                $0.disabled = true
                $0.tag = Row.approval.tag
                $0.title = Row.approval.localized
                $0.formatter = formatter
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.displayValueFor?(row.value) {
                        self.shareValue(text)
                    }
                })
        
            <<< DecimalRow() {
                $0.disabled = true
                $0.tag = Row.productivity.tag
                $0.title = Row.productivity.localized
                $0.formatter = formatter
                }.cellUpdate { cell, row in
                    self.updateCell(cell)
                }.onCellSelection({ (cell, row) in
                    if let text = row.displayValueFor?(row.value) {
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .floor
        formatter.positiveFormat = "#.##"
        formatter.positiveSuffix = "%"

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
        
        if let row: TextRow = self.form.rowBy(tag: Row.vote.tag) {
            row.value = delegate.vote
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
//            row.reload()
            row.evaluateHidden()
        }
    }
    
    // MARK: - Privare tools
    private func updateCell(_ cell: BaseCell) {
        cell.textLabel?.textColor = UIColor.adamantPrimary
        cell.detailTextLabel?.textColor = UIColor.adamantSecondary
        
        let font = UIFont.adamantPrimary(size: 17)
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
