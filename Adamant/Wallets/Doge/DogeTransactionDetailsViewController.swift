//
//  DogeTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka

class DogeTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: Rows & Sections
    enum DogeRows {
        case inputs, totalIn, outputs, totalOut
        
        var tag: String {
            switch self {
            case .inputs: return "inputs"
            case .totalIn: return "totalIn"
            case .outputs: return "outputs"
            case .totalOut: return "totalOut"
            }
        }
        
        var localized: String {
            switch self {
            case .inputs: return "Inputs"
            case .totalIn: return "Total In"
            case .outputs: return "Outputs"
            case .totalOut: return "Total Out"
            }
        }
    }
    
    // MARK: - Dependencies
    
    weak var service: DogeWalletService?
    
    // MARK: - Properties
    
    private var blockInfo: (hash: String, height: String)? = nil
    
    private let autoupdateInterval: TimeInterval = 5.0
    weak var timer: Timer?
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return control
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        currencySymbol = DogeWalletService.currencySymbol
        
        super.viewDidLoad()
        if service != nil { tableView.refreshControl = refreshControl }
        
        // MARK: Cleanup rows
        if let section = form.sectionBy(tag: Sections.details.tag) {
            let rows: [Rows] = [.from, .to, .amount, .block]
            
            for row in rows {
                if let r = form.rowBy(tag: row.tag), let index = section.firstIndex(of: r) {
                    section.remove(at: index)
                }
            }
        }
        
        // MARK: Add rows
        addRows()
        
        // MARK: Update block number
        updateBlockNumber()
        
        // MARK: Start update
        if transaction != nil {
            startUpdate()
        }
    }
    
    deinit {
        stopUpdate()
    }
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        let id = transaction.txId
        
        return URL(string: "\(AdamantResources.dogeExplorerAddress)\(id)")
    }
    
    @objc func refresh() {
        updateTransaction { [weak self] error in
            self?.refreshControl.endRefreshing()
            
            if let error = error {
                self?.dialogService.showRichError(error: error)
            }
        }
    }
    
    // MARK: Autoupdate
    
    func startUpdate() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: autoupdateInterval, repeats: true) { [weak self] _ in
            self?.updateTransaction() // Silent, without errors
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
    }
    
    // MARK: Updating methods
    
    func updateTransaction(completion: ((RichError?) -> Void)? = nil) {
        guard let service = service, let id = transaction?.txId else {
            completion?(nil)
            return
        }

        service.getTransaction(by: id) { [weak self] result in
            switch result {
            case .success(let trs):
                self?.transaction = trs
                
                if let blockInfo = self?.blockInfo, blockInfo.hash == trs.blockHash {
                    // No need to update block id
                } else {
                    self?.updateBlockNumber()
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
                
                completion?(nil)
                
            case .failure(let error):
                completion?(error)
            }
        }
    }
    
    func updateBlockNumber() {
        guard let blockHash = (transaction as? DogeRawTransaction)?.blockHash else {
            if blockInfo != nil {
                blockInfo = nil
                
                if let row = form.rowBy(tag: Rows.block.tag) {
                    DispatchQueue.main.async {
                        row.updateCell()
                    }
                }
            }
            
            return
        }
        
        service?.getBlockId(by: blockHash) { [weak self] result in
            switch result {
            case .success(let height):
                self?.blockInfo = (hash: blockHash, height: height)
                
                guard let row: LabelRow = self?.form.rowBy(tag: Rows.block.tag) else {
                    break
                }
                
                DispatchQueue.main.async {
                    row.value = height
                    row.updateCell()
                }
                
            case .failure:
                break
            }
        }
    }
}

// MARK: - Rows
private extension DogeTransactionDetailsViewController {
    func addRows() {
        // MARK: Inputs
        
        let inputsRow = LabelRow() {
            $0.disabled = true
            $0.tag = DogeRows.inputs.tag
            $0.title = DogeRows.inputs.localized
            
            if let value = (transaction as? DogeRawTransaction)?.inputs.count {
                $0.value = String(value)
            } else {
                $0.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let t = self?.transaction as? DogeRawTransaction {
                row.value = String(t.inputs.count)
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
        
        let totalInRow = DecimalRow() {
            $0.disabled = true
            $0.tag = DogeRows.totalIn.tag
            $0.title = DogeRows.totalIn.localized
            $0.formatter = AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
            
            $0.value = (transaction as? DogeRawTransaction)?.valueIn.doubleValue
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let value = row.value {
                let text = AdamantBalanceFormat.full.format(value, withCurrencySymbol: self?.currencySymbol ?? nil)
                self?.shareValue(text, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let doge = self?.transaction as? DogeRawTransaction {
                row.value = doge.valueIn.doubleValue
            } else {
                row.value = nil
            }
        }
        
        // MARK: Outputs
        
        let outputsRow = LabelRow() {
            $0.disabled = true
            $0.tag = DogeRows.outputs.tag
            $0.title = DogeRows.outputs.localized
            
            if let value = (transaction as? DogeRawTransaction)?.outputs.count {
                $0.value = String(value)
            } else {
                $0.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let t = self?.transaction as? DogeRawTransaction {
                row.value = String(t.outputs.count)
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
        
        let totalOutRow = DecimalRow() {
            $0.disabled = true
            $0.tag = DogeRows.totalOut.tag
            $0.title = DogeRows.totalOut.localized
            $0.formatter = AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
            
            $0.value = (transaction as? DogeRawTransaction)?.valueOut.doubleValue
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (cell, row) in
            if let value = row.value {
                let text = AdamantBalanceFormat.full.format(value, withCurrencySymbol: self?.currencySymbol ?? nil)
                self?.shareValue(text, from: cell)
            }
        }.cellUpdate { [weak self] (cell, row) in
            cell.textLabel?.textColor = .black
            
            if let doge = self?.transaction as? DogeRawTransaction {
                row.value = doge.valueOut.doubleValue
            } else {
                row.value = nil
            }
        }
        
        let blockRow = LabelRow() { [weak self] in
            $0.disabled = true
            $0.tag = Rows.block.tag
            $0.title = Rows.block.localized
            
            if let value = self?.blockInfo?.height {
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
            
            if let value = self?.blockInfo?.height {
                row.value = value
            } else {
                row.value = TransactionDetailsViewControllerBase.awaitingValueString
            }
        }
        
        if let section = form.sectionBy(tag: Sections.details.tag) {
            let rows = [inputsRow, totalInRow, outputsRow, totalOutRow]
            
            if let row = form.rowBy(tag: Rows.date.tag) {
                try! section.insert(row: rows[0], after: row)
                try! section.insert(row: rows[1], after: rows[0])
                try! section.insert(row: rows[2], after: rows[1])
                try! section.insert(row: rows[3], after: rows[2])
            } else {
                section.append(contentsOf: rows)
            }
            
            if let row = form.rowBy(tag: Rows.confirmations.tag) {
                try! section.insert(row: blockRow, after: row)
            } else {
                section.append(blockRow)
            }
        }
    }
}
