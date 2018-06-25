//
//  ETHTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import web3swift
import BigInt

class ETHTransactionDetailsViewController: FormViewController {
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
            }
        }
    }
    
    // MARK: - Dependencies
    var dialogService: DialogService!
    var ethApiService: EthApiServiceProtocol!
    
    // MARK: - Properties
    var transaction: EthTransaction?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let transaction = transaction else {
            return
        }
        
        guard let feeString = Web3.Utils.formatToEthereumUnits(BigUInt(EthApiService.defaultGasPrice * EthApiService.transferGas), toUnits: .eth, decimals: 8), let fee = Double(feeString) else {
            return
        }

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .decimal
        currencyFormatter.roundingMode = .floor
        currencyFormatter.positiveFormat = "#.######## ETH"
        
        // MARK: - Transfer section
        form +++ Section()
            
            <<< TextRow() {
                $0.disabled = true
                $0.title = Row.transactionNumber.localized
                $0.value = transaction.hash
                }
            <<< TextRow() {
                $0.disabled = true
                $0.title = Row.from.localized
                $0.value = transaction.from
            }
            <<< TextRow() {
                $0.disabled = true
                $0.title = Row.to.localized
                $0.value = transaction.to
            }
            <<< DateRow() {
                $0.disabled = true
                $0.title = Row.date.localized
                $0.value = transaction.date
            }
            
            <<< TextRow() {
                $0.disabled = true
                $0.title = Row.amount.localized
//                $0.formatter = currencyFormatter
                $0.value = transaction.formattedValue()
                }
            
            <<< DecimalRow() {
                $0.title = Row.fee.localized
                $0.value = fee
                $0.disabled = true
                $0.formatter = currencyFormatter
            }
            <<< TextRow() {
                $0.title = Row.confirmations.localized
                $0.value = transaction.confirmations
                $0.disabled = true
        }
        
        // MARK: - UI
        navigationAccessoryView.tintColor = UIColor.adamantPrimary
        
        for row in form.allRows {
            row.baseCell?.textLabel?.font = UIFont.adamantPrimary(size: 17)
            row.baseCell?.textLabel?.textColor = UIColor.adamantPrimary
            row.baseCell?.tintColor = UIColor.adamantPrimary
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
