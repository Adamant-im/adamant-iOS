//
//  DelegatesListViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - Localization
extension String.adamantLocalized {
    struct delegates {
        static let title = NSLocalizedString("Delegates.Title", comment: "Delegates page: scene title")
        
        static let notEnoughtTokensForVote = NSLocalizedString("Delegates.NotEnoughtTokensForVote", comment: "Delegates tab: Message about 50 ADM fee for vote")
        
        static let timeOutBeforeNewVote = NSLocalizedString("Delegates.timeOutBeforeNewVote", comment: "Delegates tab: Message about time out for new vote")
        
        static let success = NSLocalizedString("Delegates.Vote.Success", comment: "Delegates: Message for Successfull voting")
        
        private init() { }
    }
}

class DelegatesListViewController: UIViewController {
    
    // MARK: - Wrapper
    class CheckedDelegate {
        var delegate: Delegate
        var isChecked: Bool = false
        var isUpdating: Bool = false
        
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
    private var filteredDelegates: [Int]?
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    
    private var forcedUpdateTimer: Timer?
    
    private var searchController: UISearchController?
    private var loadingView: LoadingView?
    private var originalInsets: UIEdgeInsets?
    private var didShow: Bool = false

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

    @IBOutlet weak var infoViewBottomConstain: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Initial
        navigationItem.title = String.adamantLocalized.delegates.title
        tableView.register(AdamantDelegateCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = 50
        tableView.addSubview(self.refreshControl)
        
        // MARK: Search controller
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
            
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = true
            searchController = controller
            
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
        setupLoadingView()
        handleRefresh(refreshControl)
        
        // Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        setColors()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Fix for UISplitViewController with UINavigationController with UISearchController.
        // UISplitView in collapsed mode can't figure out what navigation item is topmost, and in viewDidLoad method searchController gets assigned to a wrong navigation item.
        if #available(iOS 11.0, *) {
            if navigationItem.searchController == nil {
                navigationItem.searchController = searchController
            }
        }
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
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            if #available(iOS 11.0, *) {
            } else if infoViewBottomConstain.constant == 0.0, let height = tabBarController?.tabBar.bounds.height {
                infoViewBottomConstain.constant = -height
                tableView.contentInset.bottom = 0.0
                tableView.scrollIndicatorInsets.bottom = 0.0
            }
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
                    if let i = delegates.firstIndex(where: { $0.username == name }) {
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
                self.removeLoadingView()
            }
        }
    }
    
    @objc private func activateSearch() {
        if #available(iOS 11.0, *), let bar = navigationItem.searchController?.searchBar, !bar.isFirstResponder {
            bar.becomeFirstResponder()
        }
    }
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
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
            return UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        
        let checkedDelegate = checkedDelegateFor(indexPath: indexPath)
        let delegate = checkedDelegate.delegate
        cell.backgroundColor = UIColor.adamant.cellColor
        
        cell.title = [String(delegate.rank), delegate.username].joined(separator: " ")
        cell.subtitle = delegate.address
        cell.delegateIsActive = delegate.rank <= activeDelegates
        cell.delegate = self
        cell.isUpvoted = delegate.voted
        cell.isChecked = checkedDelegate.isChecked
        cell.isUpdating = checkedDelegate.isUpdating
        
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
        if forcedUpdateTimer != nil {
            self.dialogService.showWarning(withMessage: String.adamantLocalized.delegates.timeOutBeforeNewVote)
            return
        }
        
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

                checkedDelegates.forEach {
                    $1.isChecked = false
                    $1.delegate.voted = !$1.delegate.voted
                    $1.isUpdating = true
                }
                
                DispatchQueue.main.async {
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
        
        let timer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(updateTimerCallback), userInfo: nil, repeats: false)
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
        let newVotesColor = changes.count > maxVotes ? UIColor.adamant.alert : UIColor.adamant.primary
        let totalVotesColor = totalVoted > maxTotalVotes ? UIColor.adamant.alert : UIColor.adamant.primary
        
        DispatchQueue.onMainAsync { [weak self] in
            guard let self = self else { return }
            
            self.upVotesLabel.text = "\(upvoted)"
            self.downVotesLabel.text = "\(downvoted)"
            self.newVotesLabel.text = "\(changes.count)/\(self.maxVotes)"
            self.totalVotesLabel.text = "\(totalVoted)/\(self.maxTotalVotes)"
            
            self.voteBtn.isEnabled = votingEnabled
            self.newVotesLabel.textColor = newVotesColor
            self.totalVotesLabel.textColor = totalVotesColor
        }
    }
    
    private func setupLoadingView() {
        let loadingView = LoadingView()
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        loadingView.startAnimating()
        
        self.loadingView = loadingView
    }
    
    private func removeLoadingView() {
        guard loadingView != nil else { return }
        
        UIView.animate(
            withDuration: 0.25,
            animations: { [weak loadingView] in loadingView?.alpha = .zero },
            completion: { [weak loadingView] _ in
                loadingView?.removeFromSuperview()
                loadingView = nil
            }
        )
    }
}

extension DelegatesListViewController {
    // MARK: Keyboard
    @objc private func keyboardWillShow(notification: Notification) {
        // For some reason we will receive 2 notifications
        guard !didShow else { return }
        didShow = true
        
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else {
            return
        }
        
        originalInsets = tableView.contentInset
        
        let gap = UIScreen.main.bounds.height - tableView.bounds.height + tableView.frame.origin.y
        let bottom = frame.cgRectValue.size.height - gap
        
        var contentInsets = tableView.contentInset
        contentInsets.bottom = bottom
        
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        guard didShow else { return }
        didShow = false
        
        if let insets = originalInsets {
            tableView.contentInset = insets
            tableView.scrollIndicatorInsets = insets
        } else {
            var contentInsets = tableView.contentInset
            contentInsets.bottom = 0.0
            tableView.contentInset = contentInsets
            tableView.scrollIndicatorInsets = contentInsets
        }
    }
}
