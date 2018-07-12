//
//  DelegatesListViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import M13Checkbox

class DelegatesListViewController: UIViewController {
    
    let cellIdentifier = "cell"

    // MARK: - Dependencies
    
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    let activeDelegates: Int = 101
    var delegates: [Delegate] = [Delegate]()
    var newVotesDelegates: [Delegate] = [Delegate]()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.adamantPrimary
        
        return refreshControl
    }()
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var upVotesLabel: UILabel!
    @IBOutlet weak var downVotesLabel: UILabel!
    @IBOutlet weak var newVotesLabel: UILabel!
    @IBOutlet weak var totalVotesLabel: UILabel!
    
    @IBOutlet weak var voteBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib.init(nibName: "DelegateCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.addSubview(self.refreshControl)
        
        self.upVotesLabel.text = ""
        self.downVotesLabel.text = ""
        self.newVotesLabel.text = ""
        self.totalVotesLabel.text = ""
        
        self.refreshControl.beginRefreshing()
        handleRefresh(self.refreshControl)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantDelegate.stateChanged, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let address = notification.userInfo?[AdamantUserInfoKey.Delegate.address] as? String, let state = notification.userInfo?[AdamantUserInfoKey.Delegate.newState] as? Bool else {
                return
            }
            
            guard var delegate = self?.delegates.first(where: { (delegate) -> Bool in
                delegate.address == address
            }) else {
                return
            }
            
            if let index = self?.newVotesDelegates.index(where: { (delegate) -> Bool in
                delegate.address == address
            }) {
                self?.newVotesDelegates.remove(at: index)
            } else {
                delegate.voted = state
                self?.newVotesDelegates.append(delegate)
            }
            
            self?.updateVotePanel()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        if let address = accountService.account?.address {
            apiService.getDelegatesWithVotes(for: address, limit: activeDelegates) { (result) in
                switch result {
                case .success(let delegates):
                    print(delegates)
                    self.delegates = delegates
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print(error)
                    self.dialogService.showError(withMessage: error.localized, error: error)
                }
                
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
                    self.updateVotePanel()
                }
            }
        } else {
            refreshControl.endRefreshing()
            self.dialogService.showRichError(error: AccountServiceError.userNotLogged)
        }
    }
    
    private func updateVotePanel() {
        if self.newVotesDelegates.count > 0 {
            voteBtn.isEnabled = true
        } else {
            voteBtn.isEnabled = false
        }
        
        DispatchQueue.global().async {
            let voted = self.delegates.filter({ (delegate) -> Bool in
                return delegate.voted
            })
            
            let upVoted = self.newVotesDelegates.filter({ (delegate) -> Bool in
                return delegate.voted == true
            })
            
            let downVoted = self.newVotesDelegates.filter({ (delegate) -> Bool in
                return delegate.voted == false
            })
            
            DispatchQueue.main.async {
                self.upVotesLabel.text = "\(upVoted.count)"
                self.downVotesLabel.text = "\(downVoted.count)"
                self.newVotesLabel.text = "\(self.newVotesDelegates.count)/30"
                self.totalVotesLabel.text = "\(voted.count)/\(self.delegates.count)"
            }
        }
    }
    
    @IBAction func vote(_ sender: Any) {
        guard self.newVotesDelegates.count > 0 else {
            // TODO: Show error message
            return
        }
        if let account = accountService.account, let keypair = accountService.keypair {
            let balance = (account.balance as NSDecimalNumber).doubleValue
            if balance > 50 {
                let voted = self.newVotesDelegates.sorted(by: { (item1, item2) -> Bool in
                    var check1: Int = 0
                    var check2: Int = 0
                    if item1.voted == true {
                        check1 = 1
                    }
                    if item2.voted == true {
                        check2 = 1
                    }
                    return check1 < check2
                }).map({ (delegate) -> String in
                    return delegate.voted ? "+\(delegate.publicKey)" : "-\(delegate.publicKey)"
                })
                
                self.apiService.voteForDelegates(from: account.address, keypair: keypair, votes: voted) { (result) in
                    switch result {
                    case .success(let transactionId):
                        print("Vote transaction ID: \(transactionId)")
                        break
                        
                    case .failure(let error):
                        self.dialogService.showRichError(error: TransfersProviderError.serverError(error))
                    }
                }
            } else {
                self.dialogService.showRichError(error: ChatsProviderError.notEnoughtMoneyToSend)
            }
        } else {
            self.dialogService.showRichError(error: AccountServiceError.userNotLogged)
        }
    }
}

// MARK: - UITableView
extension DelegatesListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegates.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let delegate = delegates[indexPath.row]
        guard let controller = router.get(scene: AdamantScene.Delegates.delegateDetails) as? DelegateDetailsViewController else {
            return
        }

        controller.delegate = delegate
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? DelegateCell else {
                return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let delegate = delegates[indexPath.row]
        
        cell.nameLabel.text = delegate.username
        cell.rankLabel.text = "#\(delegate.rank)"
        cell.addressLabel.text = delegate.address
        cell.statusLabel.text = delegate.rank <= activeDelegates ? "●" : "○"
        
        if let delegate = self.newVotesDelegates.first(where: { (vote) -> Bool in
            return vote.address == delegate.address
        }) {
            cell.checkbox.checkState = delegate.voted ? .checked : .unchecked
        } else {
            cell.checkbox.checkState = delegate.voted ? .checked : .unchecked
        }
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}
