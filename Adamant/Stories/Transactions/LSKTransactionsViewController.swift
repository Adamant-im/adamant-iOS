//
//  LSKTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 17/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Lisk
import web3swift
import BigInt

class LSKTransactionsViewController: TransactionsViewController {
    
    // MARK: - Dependencies
    var lskApiService: LskApiService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [Transactions.TransactionModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl.beginRefreshing()
        
        handleRefresh(self.refreshControl)
    }
    
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.lskApiService.getTransactions({ (result) in
            switch result {
            case .success(let transactions):
                self.transactions = transactions
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                break
            case .failure(let error):
                if case .internalError(let message, _ ) = error {
                    let localizedErrorMessage = NSLocalizedString(message, comment: "TransactionList: 'Transactions not found' message.")
                    self.dialogService.showWarning(withMessage: localizedErrorMessage)
                } else {
                    self.dialogService.showError(withMessage: String.adamantLocalized.transactionList.notFound, error: error)
                }
                break
            }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    override func currentAddress() -> String {
        guard let address = lskApiService.account?.address else {
            return ""
        }
        return address
    }

}

// MARK: - UITableView
extension LSKTransactionsViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        guard let controller = router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? TransactionDetailsViewControllerBase else {
            return
        }
        
        controller.transaction = transaction
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TransactionTableViewCell else {
            // TODO: Display & Log error
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let transaction = transactions[indexPath.row]
        
        cell.accessoryType = .disclosureIndicator
        
        configureCell(cell, for: transaction)
        return cell
    }
}

extension Transactions.TransactionModel: TransactionDetailsProtocol {
    var senderAddress: String {
        return self.senderId
    }
    
    var recipientAddress: String {
        return self.recipientId ?? ""
    }
    
    var sentDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(self.timestamp) + Constants.Time.epochSeconds)
    }
    
    var amountValue: Double {
        guard let string = Web3.Utils.formatToPrecision(BigUInt(self.amount) ?? BigUInt(0), numberDecimals: 8, formattingDecimals: 8, decimalSeparator: ".", fallbackToScientific: false), let value = Double(string) else {
            return 0
        }
        
        return value
    }
    
    var feeValue: Double {
        guard let string = Web3.Utils.formatToPrecision(BigUInt(self.fee) ?? BigUInt(0), numberDecimals: 8, formattingDecimals: 8, decimalSeparator: ".", fallbackToScientific: false), let value = Double(string) else {
            return 0
        }
        
        return value
    }
    
    var confirmationsValue: String {
        return "\(self.confirmations)"
    }
    
    var block: String {
        return self.blockId
    }
    
    var showGoToExplorer: Bool {
        return true
    }
    
    var explorerUrl: URL? {
        return URL(string: "https://testnet-explorer.lisk.io/tx/\(id)")
    }
    
    var showGoToChat: Bool {
        return false
    }
    
    var chatroom: Chatroom? {
        return nil
    }
    
    var currencyCode: String {
        return "LSK"
    }
}
