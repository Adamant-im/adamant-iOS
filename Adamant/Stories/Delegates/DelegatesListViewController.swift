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
	let maxVotes = 33
	let maxTotalVotes = 101
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
	
	private var forcedUpdateTimer: Timer? = nil

	
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
		
		if let timer = forcedUpdateTimer {
			timer.invalidate()
			forcedUpdateTimer = nil
		}
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
		
		
		// MARK: Build request and update UI
		
		var votes = [DelegateVote]()
		
		for indexPath in delegatesChanges {
			let delegate = delegates[indexPath.row]
			let vote: DelegateVote = delegate.voted ? .downvote(publicKey: delegate.publicKey) : .upvote(publicKey: delegate.publicKey)
			votes.append(vote)
		}
		
		let indicies = delegatesChanges
		
		// MARK: Send
		
		dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
		
		apiService.voteForDelegates(from: account.address, keypair: keypair, votes: votes) { result in
			switch result {
			case .success:
				self.dialogService.showSuccess(withMessage: String.adamantLocalized.delegates.success)
				
				DispatchQueue.main.async {
					for indexPath in indicies {
						var delegate = self.delegates[indexPath.row]
						delegate.voted = !delegate.voted
						self.delegates[indexPath.row] = delegate
					}
					
					self.delegatesChanges.removeAll()
					self.updateVotePanel()
					self.tableView.reloadRows(at: indicies, with: .none)
					
					self.scheduleUpdate() // schedule on main
				}
				
			case .failure(let error):
				self.dialogService.showRichError(error: TransfersProviderError.serverError(error))
			}
		}
	}
}


// MARK: - Private
extension DelegatesListViewController {
	private func scheduleUpdate() {
		if let timer = forcedUpdateTimer {
			timer.invalidate()
			forcedUpdateTimer = nil
		}
		
		let timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(updateTimerCallback), userInfo: nil, repeats: false)
		forcedUpdateTimer = timer
	}
	
	@objc private func updateTimerCallback(_ timer: Timer) {
		handleRefresh(refreshControl)
		forcedUpdateTimer = nil
	}
	
	private func updateVotePanel() {
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
		
		let totalVoted = delegates.reduce(0) { $0 + ($1.voted ? 1 : 0) } + upvoted - downvoted
		
		let votingEnabled = delegatesChanges.count <= maxVotes && totalVoted <= maxTotalVotes
		let newVotesColor = delegatesChanges.count > maxVotes ? UIColor.red : UIColor.darkText
		let totalVotesColor = totalVoted > maxTotalVotes ? UIColor.red : UIColor.darkText
		
		
		if Thread.isMainThread {
			upVotesLabel.text = String(upvoted)
			downVotesLabel.text = String(downvoted)
			newVotesLabel.text = "\(delegatesChanges.count)/\(maxVotes)"
			totalVotesLabel.text = "\(totalVoted)/\(maxTotalVotes)"
			
			voteBtn.isEnabled = votingEnabled
			newVotesLabel.textColor = newVotesColor
			totalVotesLabel.textColor = totalVotesColor
		} else {
			let changes = delegatesChanges.count
			let max = maxVotes
			let totalMax = maxTotalVotes
			
			DispatchQueue.main.async { [unowned self] in
				self.upVotesLabel.text = "\(upvoted)"
				self.downVotesLabel.text = "\(downvoted)"
				self.newVotesLabel.text = "\(changes)/\(max)"
				self.totalVotesLabel.text = "\(totalVoted)/\(totalMax)"
				
				self.voteBtn.isEnabled = votingEnabled
				self.newVotesLabel.textColor = newVotesColor
				self.totalVotesLabel.textColor = totalVotesColor
			}
		}
	}
}
