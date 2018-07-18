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
	
	// MARK: - Wrapper
	class CheckedDelegate {
		var delegate: Delegate
		var isChecked: Bool = false
		
		init(delegate: Delegate) {
			self.delegate = delegate
		}
	}
	
	
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
	
    private (set) var delegates: [CheckedDelegate] = [CheckedDelegate]()
	private var filteredDelegates: [Int]? = nil
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.adamantPrimary
        
        return refreshControl
    }()
	
	private var forcedUpdateTimer: Timer? = nil

	// MARK: Tools
	
	// Can start with 'u' or 'U', then 1-20 digits
	private let possibleAddressRegEx = try! NSRegularExpression(pattern: "^[uU]{0,1}\\d{1,20}$", options: [])
	
	
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
		
		// MARK: Initial
        navigationItem.title = String.adamantLocalized.delegates.title
        tableView.register(UINib.init(nibName: "AdamantDelegateCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
		tableView.rowHeight = 50
		tableView.addSubview(self.refreshControl)
		
		// MARK: Search controller
		if #available(iOS 11.0, *) {
			let searchController = UISearchController(searchResultsController: nil)
			searchController.searchResultsUpdater = self
			searchController.obscuresBackgroundDuringPresentation = false
			searchController.hidesNavigationBarDuringPresentation = false
			navigationItem.searchController = searchController
			definesPresentationContext = true
			navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .search, target: self, action: #selector(activateSearch))
		}
		
		// MARK: Reset UI
        upVotesLabel.text = ""
        downVotesLabel.text = ""
        newVotesLabel.text = ""
        totalVotesLabel.text = ""
		voteBtn.isEnabled = false
		
		// MARK: Load data
//        refreshControl.beginRefreshing() // Nasty glitches
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
				let checkedNames = self.delegates.filter { $0.isChecked }.map { $0.delegate.username }
				let checkedDelegates = delegates.map { CheckedDelegate(delegate: $0) }
				for name in checkedNames {
					if let i = delegates.index(where: { $0.username == name }) {
						checkedDelegates[i].isChecked = true
					}
				}
				
				self.delegates = checkedDelegates
				
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			case .failure(let error):
				self.dialogService.showRichError(error: error)
			}
			
			DispatchQueue.main.async {
				refreshControl.endRefreshing()
				self.updateVotePanel()
			}
		}
    }
	
	@objc private func activateSearch() {
		if #available(iOS 11.0, *), let bar = navigationItem.searchController?.searchBar, !bar.isFirstResponder {
			bar.becomeFirstResponder()
		}
	}
}


// MARK: - UITableView
extension DelegatesListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let filtered = filteredDelegates {
			return filtered.count
		} else {
			return delegates.count
		}
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let controller = router.get(scene: AdamantScene.Delegates.delegateDetails) as? DelegateDetailsViewController else {
			return
		}
		
        controller.delegate = checkedDelegateFor(indexPath: indexPath).delegate
		
        navigationController?.pushViewController(controller, animated: true)
    }
	
	// MARK: Cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AdamantDelegateCell else {
			return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
		
		let checkedDelegate = checkedDelegateFor(indexPath: indexPath)
		let delegate = checkedDelegate.delegate
        
        cell.nameLabel.text = delegate.username
        cell.rankLabel.text = String(delegate.rank)
        cell.addressLabel.text = delegate.address
        cell.delegateIsActive = delegate.rank <= activeDelegates
		cell.accessoryType = .disclosureIndicator
		cell.delegate = self
		cell.checkmarkColor = UIColor.adamantPrimary
		
		cell.isUpvoted = delegate.voted
		
		cell.setIsChecked(checkedDelegate.isChecked, animated: false)
		
        return cell
    }
}


// MARK: - AdamantDelegateCellDelegate
extension DelegatesListViewController: AdamantDelegateCellDelegate {
	func delegateCell(_ cell: AdamantDelegateCell, didChangeCheckedStateTo state: Bool) {
		guard let indexPath = tableView.indexPath(for: cell) else {
			return
		}
		
		checkedDelegateFor(indexPath: indexPath).isChecked = state
		updateVotePanel()
	}
}


// MARK: - Voting
extension DelegatesListViewController {
	@IBAction func vote(_ sender: Any) {
		// MARK: Prepare
		let checkedDelegates = delegates.enumerated().filter { $1.isChecked }
		guard checkedDelegates.count > 0 else {
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
		
		for checked in checkedDelegates {
			let delegate = checked.element.delegate
			let vote: DelegateVote = delegate.voted ? .downvote(publicKey: delegate.publicKey) : .upvote(publicKey: delegate.publicKey)
			votes.append(vote)
		}

		// MARK: Send
		
		dialogService.showProgress(withMessage: nil, userInteractionEnable: false)

		apiService.voteForDelegates(from: account.address, keypair: keypair, votes: votes) { result in
			switch result {
			case .success:
				self.dialogService.showSuccess(withMessage: String.adamantLocalized.delegates.success)

				DispatchQueue.main.async {
					checkedDelegates.forEach {
						$1.isChecked = false
						
						var delegate = $1.delegate
						delegate.voted = !delegate.voted
						$1.delegate = delegate
					}
					
					self.tableView.reloadData()
					self.updateVotePanel()
					self.scheduleUpdate()
				}

			case .failure(let error):
				self.dialogService.showRichError(error: TransfersProviderError.serverError(error))
			}
		}
	}
}


// MARK: - UISearchResultsUpdating
extension DelegatesListViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		if let search = searchController.searchBar.text?.lowercased(), search.count > 0 {
			let searchAddress = possibleAddressRegEx.matches(in: search, options: [], range: NSRange(location: 0, length: search.count)).count == 1
			
			
			
			let filter: ((Int, CheckedDelegate) -> Bool)
			if searchAddress {
				filter = { $1.delegate.username.lowercased().contains(search) || $1.delegate.address.lowercased().contains(search) }
			} else {
				filter = { $1.delegate.username.lowercased().contains(search) }
			}
			
			filteredDelegates = delegates.enumerated().filter(filter).map { $0.offset }
		} else {
			filteredDelegates = nil
		}
		
		tableView.reloadData()
	}
}


// MARK: - Private
extension DelegatesListViewController {
	private func checkedDelegateFor(indexPath: IndexPath) -> CheckedDelegate {
		if let filtered = filteredDelegates {
			return delegates[filtered[indexPath.row]]
		} else {
			return delegates[indexPath.row]
		}
	}
	
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
		let changes = delegates.filter { $0.isChecked }.map { $0.delegate }
		
		var upvoted = 0
		var downvoted = 0
		for delegate in changes {
			if delegate.voted {
				downvoted += 1
			} else {
				upvoted += 1
			}
		}
		
		let totalVoted = delegates.reduce(0) { $0 + ($1.delegate.voted ? 1 : 0) } + upvoted - downvoted
		
		let votingEnabled = changes.count > 0 && changes.count <= maxVotes && totalVoted <= maxTotalVotes
		let newVotesColor = changes.count > maxVotes ? UIColor.red : UIColor.darkText
		let totalVotesColor = totalVoted > maxTotalVotes ? UIColor.red : UIColor.darkText
		
		
		if Thread.isMainThread {
			upVotesLabel.text = String(upvoted)
			downVotesLabel.text = String(downvoted)
			newVotesLabel.text = "\(changes.count)/\(maxVotes)"
			totalVotesLabel.text = "\(totalVoted)/\(maxTotalVotes)"
			
			voteBtn.isEnabled = votingEnabled
			newVotesLabel.textColor = newVotesColor
			totalVotesLabel.textColor = totalVotesColor
		} else {
			let changes = changes.count
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
