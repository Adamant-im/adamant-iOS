//
//  DelegatesListViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

// MARK: - Localization
extension String.adamantLocalized {
    struct delegates {
        static let title = NSLocalizedString("Delegates.Title", comment: "Delegates page: scene title")
        
        static let notEnoughtTokensForVote = NSLocalizedString("Delegates.NotEnoughtTokensForVote", comment: "Delegates tab: Message about 50 ADM fee for vote")
        
        static let success = NSLocalizedString("Delegates.Vote.Success", comment: "Delegates: Message for Successfull voting")
		
        private init() { }
    }
}

class DelegatesListViewController: UIViewController {
	
    // MARK: - Dependencies
    
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
	
	
	// MARK: - Constants
	
	let votingCost: Decimal = Decimal(integerLiteral: 50)
	let activeDelegates = 101
	let maxVotes = 30
	private let cellIdentifier = "cell"
	
    // MARK: - Properties
	
    private (set) var delegates: [Delegate] = [Delegate]()
    private var delegatesChanges: [IndexPath] = [IndexPath]()
    
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

	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        
        navigationItem.title = String.adamantLocalized.delegates.title
        
        tableView.register(UINib.init(nibName: "AdamantDelegateCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
		tableView.rowHeight = 50
		tableView.addSubview(self.refreshControl)
        
        upVotesLabel.text = ""
        downVotesLabel.text = ""
        newVotesLabel.text = ""
        totalVotesLabel.text = ""
        
        refreshControl.beginRefreshing()
        handleRefresh(refreshControl)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
		}
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}

    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
		guard let address = accountService.account?.address else {
			refreshControl.endRefreshing()
			self.dialogService.showRichError(error: AccountServiceError.userNotLogged)
			return
		}
		
		apiService.getDelegatesWithVotes(for: address, limit: activeDelegates) { (result) in
			switch result {
			case .success(let delegates):
				self.delegates = delegates
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			case .failure(let error):
				self.dialogService.showError(withMessage: error.localized, error: error)
			}
			
			DispatchQueue.main.async {
				refreshControl.endRefreshing()
				self.updateVotePanel()
			}
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let controller = router.get(scene: AdamantScene.Delegates.delegateDetails) as? DelegateDetailsViewController else {
			return
		}
		
        let delegate = delegates[indexPath.row]
        controller.delegate = delegate
		
        navigationController?.pushViewController(controller, animated: true)
    }
	
	// MARK: Cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AdamantDelegateCell else {
			return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let delegate = delegates[indexPath.row]
        
        cell.nameLabel.text = delegate.username
        cell.rankLabel.text = String(delegate.rank)
        cell.addressLabel.text = delegate.address
        cell.delegateIsActive = delegate.rank <= activeDelegates
		cell.accessoryType = .disclosureIndicator
		cell.delegate = self
		cell.checkmarkColor = UIColor.adamantPrimary
		
		cell.isUpvoted = delegate.voted
		
		cell.setIsChecked(delegatesChanges.contains(indexPath), animated: false)
		
        return cell
    }
}


// MARK: - AdamantDelegateCellDelegate
extension DelegatesListViewController: AdamantDelegateCellDelegate {
	func delegateCell(_ cell: AdamantDelegateCell, didChangeCheckedStateTo state: Bool) {
		guard let indexPath = tableView.indexPath(for: cell) else {
			return
		}
		
		if state {
			if !delegatesChanges.contains(indexPath) {
				delegatesChanges.append(indexPath)
			}
		} else if let index = delegatesChanges.index(of: indexPath) {
			delegatesChanges.remove(at: index)
		}
		
		updateVotePanel()
	}
}


// MARK: - Voting
extension DelegatesListViewController {
	@IBAction func vote(_ sender: Any) {
		// MARK: Prepare
		guard delegatesChanges.count > 0 else {
			return
		}
		
		guard let account = accountService.account, let keypair = accountService.keypair else {
			self.dialogService.showRichError(error: AccountServiceError.userNotLogged)
			return
		}
		
		guard account.balance > votingCost else {
			self.dialogService.showWarning(withMessage: String.adamantLocalized.delegates.notEnoughtTokensForVote)
			return
		}
		
		
		// MARK: Build
		
		var votes = [DelegateVote]()
		
		for indexPath in delegatesChanges {
			let delegate = delegates[indexPath.row]
			let vote: DelegateVote = delegate.voted ? .downvote(publicKey: delegate.publicKey) : .upvote(publicKey: delegate.publicKey)
			votes.append(vote)
		}
		
		
		// MARK: Send
		
		dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
		
		apiService.voteForDelegates(from: account.address, keypair: keypair, votes: votes) { [weak self] result in
			switch result {
			case .success:
				self?.dialogService.showSuccess(withMessage: String.adamantLocalized.delegates.success)
				
				if let refreshControl = self?.refreshControl {
					if Thread.isMainThread {
						refreshControl.beginRefreshing()
					} else {
						DispatchQueue.main.async {
							refreshControl.beginRefreshing()
						}
					}
					
					self?.handleRefresh(refreshControl)
				}
				
			case .failure(let error):
				self?.dialogService.showRichError(error: TransfersProviderError.serverError(error))
			}
		}
	}
}


// MARK: - Private
extension DelegatesListViewController {
	private func updateVotePanel() {
		if delegatesChanges.count > 0 {
			voteBtn.isEnabled = true
		} else {
			voteBtn.isEnabled = false
		}
		
		let changes = delegatesChanges.map { delegates[$0.row] }
		
		var upvoted = 0
		var downvoted = 0
		for delegate in changes {
			if delegate.voted {
				downvoted += 1
			} else {
				upvoted += 1
			}
		}
		
		let totalDelegates = delegates.count
		let totalChanges = delegatesChanges.count
		let totalVoted = delegates.reduce(0) { $0 + ($1.voted ? 1 : 0) }
		
		if Thread.isMainThread {
			upVotesLabel.text = String(upvoted)
			downVotesLabel.text = String(downvoted)
			newVotesLabel.text = "\(totalChanges)/\(maxVotes)"
			totalVotesLabel.text = "\(totalVoted)/\(totalDelegates)"
		} else {
			let max = maxVotes
			DispatchQueue.main.async {
				self.upVotesLabel.text = "\(upvoted)"
				self.downVotesLabel.text = "\(downvoted)"
				self.newVotesLabel.text = "\(totalChanges)/\(max)"
				self.totalVotesLabel.text = "\(totalVoted)/\(totalDelegates)"
			}
		}
	}
}
