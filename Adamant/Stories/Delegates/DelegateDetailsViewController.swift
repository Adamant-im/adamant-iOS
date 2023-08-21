//
//  DelegateDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 09/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SafariServices
import DateToolsSwift
import CommonKit

// MARK: - Localization
extension String.adamant {
    struct delegateDetails {
        static let title = String.localized("DelegateDetails.Title", comment: "Delegate details: scene title")
    }
}

// MARK: -
class DelegateDetailsViewController: UIViewController {
    
    // MARK: - Rows
    fileprivate enum Row: Int {
        case username = 0
        case rank
        case address
        case publicKey
        case vote
        case producedblocks
        case missedblocks
//        case rate
        case approval
        case productivity
        case forgingTime
        case forged
        case openInExplorer
        
        static let total = 12
        
        var localized: String {
            switch self {
            case .username: return .localized("DelegateDetails.Row.Username", comment: "Delegate Details Screen: Rows title for 'Username'")
            case .address: return .localized("DelegateDetails.Row.Address", comment: "Delegate Details Screen: Rows title for 'Address'")
            case .publicKey: return .localized("DelegateDetails.Row.PublicKey", comment: "Delegate Details Screen: Rows title for 'Public Key'")
            case .vote: return .localized("DelegateDetails.Row.VoteWeight", comment: "Delegate Details Screen: Rows title for 'Vote weight'")
            case .producedblocks: return .localized("DelegateDetails.Row.ProducedBlocks", comment: "Delegate Details Screen: Rows title for 'Produced blocks'")
            case .missedblocks: return .localized("DelegateDetails.Row.MissedBlocks", comment: "Delegate Details Screen: Rows title for 'Missed blocks'")
            case .rank: return .localized("DelegateDetails.Row.Rank", comment: "Delegate Details Screen: Rows title for 'Rank'")
            case .approval: return .localized("DelegateDetails.Row.Approval", comment: "Delegate Details Screen: Rows title for 'Approval'")
            case .productivity: return .localized("DelegateDetails.Row.Productivity", comment: "Delegate Details Screen: Rows title for 'Productivity'")
            case .forgingTime: return .localized("DelegateDetails.Row.ForgingTime", comment: "Delegate Details Screen: Rows title for 'Forging time'")
            case .forged: return .localized("DelegateDetails.Row.Forged", comment: "Delegate Details Screen: Rows title for 'Forged'")
            case .openInExplorer: return .localized("TransactionDetailsScene.Row.Explorer", comment: "Transaction details: 'Open transaction in explorer' row.")
//            case .rate: return .localized("DelegateDetails.Row.Rate", comment: "Delegate Details Screen: Rows title for 'Rate'")
            }
        }
        
        func indexPathFor(section: Int) -> IndexPath {
            return IndexPath(item: rawValue, section: section)
        }
        
        var image: UIImage? {
            switch self {
            case .openInExplorer: return .asset(named: "row_explorer")
                
            default: return nil
            }
        }
    }
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    private let delegateUrl = "https://explorer.adamant.im/delegate/"
    private let cellIdentifier = "cell"
    
    var delegate: Delegate?
    
    private let autoupdateInterval: TimeInterval = 5.0
    
    weak var timer: Timer?

    lazy var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    lazy var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [ .hour, .minute, .second ]
        formatter.unitsStyle = .brief
        formatter.zeroFormattingBehavior = .dropLeading

        return formatter
    }()
    
    private var forged: Decimal?
    private var forgingTime: TimeInterval?
    
    // Double error fix
    private var prevApiError: (date: Date, error: ApiServiceError)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let delegate = delegate {
            refreshData(with: delegate)
            navigationItem.title = delegate.username
        } else {
            navigationItem.title = String.adamant.delegateDetails.title
        }
        
        setColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
}

// MARK: - TableView data & delegate
extension DelegateDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if delegate != nil {
            return Row.total
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = Row(rawValue: indexPath.row) else {
            return
        }
        
        switch row {
        case .openInExplorer:
            guard let address = delegate?.address, let url = URL(string: delegateUrl + address) else {
                return
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            present(safari, animated: true, completion: nil)
            
        default:
            guard let cell = tableView.cellForRow(at: indexPath), let value = cell.detailTextLabel?.text, value.count > 0 else {
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
            
            let completion = { [weak self] in
                guard let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow else {
                    return
                }
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            dialogService.presentShareAlertFor(string: value,
                                               types: [.copyToPasteboard, .share],
                                               excludedActivityTypes: nil,
                                               animated: true, from: cell,
                                               completion: completion)
        }
    }
}

// MARK: - Cells
extension DelegateDetailsViewController {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let delegate = delegate, let row = Row(rawValue: indexPath.row) else {
            return UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        
        let cell: UITableViewCell
        if let c = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = c
            cell.accessoryType = .none
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        }
        cell.backgroundColor = UIColor.adamant.cellColor
        cell.textLabel?.text = row.localized
        cell.accessoryType = .none
        cell.imageView?.image = row.image
        
        switch row {
        case .username:
            cell.detailTextLabel?.text = delegate.username
            
        case .address:
            cell.detailTextLabel?.text = delegate.address
            
        case .publicKey:
            cell.detailTextLabel?.text = delegate.publicKey
            
        case .vote:
            let weight = Decimal(string: delegate.voteFair)?.shiftedFromAdamant() ?? 0
            cell.detailTextLabel?.text = AdamantBalanceFormat.short.format(weight)
            
        case .producedblocks:
            cell.detailTextLabel?.text = String(delegate.producedblocks)
            
        case .missedblocks:
            cell.detailTextLabel?.text = String(delegate.missedblocks)
            
        case .rank:
            cell.detailTextLabel?.text = String(delegate.rank)
            
        case .approval:
            let text = percentFormatter.string(for: (delegate.approval / 100.0))
            cell.detailTextLabel?.text = text
            
        case .productivity:
            let text = percentFormatter.string(for: (delegate.productivity / 100.0))
            cell.detailTextLabel?.text = text
            
        case .openInExplorer:
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.text = nil
            
        case .forgingTime:
            if let forgingTime = forgingTime {
                if forgingTime > 0 {
                    cell.detailTextLabel?.text = durationFormatter.string(from: forgingTime)
                } else {
                    cell.detailTextLabel?.text = Date.now.humanizedTime().string
                }
                
            } else {
                cell.detailTextLabel?.text = ""
            }
            
        case .forged:
            cell.detailTextLabel?.text = AdamantBalanceFormat.short.defaultFormatter.string(for: forged)
        }
        
        return cell
    }
}

// MARK: - Tools
extension DelegateDetailsViewController {
    private func refreshData(with delegate: Delegate) {
        Task {
            await apiService.getForgedByAccount(publicKey: delegate.publicKey) { [weak self] result in
                switch result {
                case .success(let details):
                    self?.forged = details.forged
                    
                    DispatchQueue.main.async {
                        guard let tableView = self?.tableView else {
                            return
                        }
                        
                        let indexPath = Row.forged.indexPathFor(section: 0)
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                case .failure(let error):
                    self?.apiServiceFailed(with: error)
                }
            }
            
            // Get forging time
            await apiService.getForgingTime(for: delegate) { [weak self] result in
                switch result {
                case .success(let seconds):
                    if seconds >= 0 {
                        self?.forgingTime = TimeInterval(exactly: seconds)
                    } else {
                        self?.forgingTime = nil
                    }
                    
                    DispatchQueue.main.async {
                        guard let tableView = self?.tableView else {
                            return
                        }
                        
                        let indexPath = Row.forgingTime.indexPathFor(section: 0)
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    
                case .failure(let error):
                    self?.apiServiceFailed(with: error)
                }
            }
        }
    }
    
    private func apiServiceFailed(with error: ApiServiceError) {
        DispatchQueue.main.async { [unowned self] in
            if let prevApiError = self.prevApiError, Date().timeIntervalSince(prevApiError.date) < 1, prevApiError.error == error { // if less than a second ago, return
                return
            }
            
            self.prevApiError = (date: Date(), error: error)
            self.dialogService.showRichError(error: error)
        }
    }
}
