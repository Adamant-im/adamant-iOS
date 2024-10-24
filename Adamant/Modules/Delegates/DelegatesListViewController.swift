//
//  DelegatesListViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import CommonKit
import MarkdownKit
import SafariServices
import Combine

// MARK: - Localization
extension String.adamant {
    enum delegates {
        static var title: String {
            String.localized("Delegates.Title", comment: "Delegates page: scene title")
        }
        static var notEnoughtTokensForVote: String {
            String.localized("Delegates.NotEnoughtTokensForVote", comment: "Delegates tab: Message about 50 ADM fee for vote")
        }
        static var timeOutBeforeNewVote: String {
            String.localized("Delegates.timeOutBeforeNewVote", comment: "Delegates tab: Message about time out for new vote")
        }
        static var success: String {
            String.localized("Delegates.Vote.Success", comment: "Delegates: Message for Successfull voting")
        }
    }
}

final class DelegatesListViewController: KeyboardObservingViewController {
    // MARK: - Wrapper
    final class CheckedDelegate {
        var delegate: Delegate
        var isChecked: Bool = false
        var isUpdating: Bool = false
        
        init(delegate: Delegate) {
            self.delegate = delegate
        }
    }
    
    // MARK: - Dependencies
    
    private let apiService: AdamantApiServiceProtocol
    private let accountService: AccountService
    private let dialogService: DialogService
    private let screensFactory: ScreensFactory
    
    // MARK: - Constants
    
    let votingCost = 50
    let activeDelegates = 101
    let maxVotes = 33
    let maxTotalVotes = 101
    private let cellIdentifier = "cell"
    
    // MARK: - Properties
    
    private var headerTextView: UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.delegate = self
        
        let attributedString = NSMutableAttributedString(
            attributedString: MarkdownParser(
                font: UIFont.preferredFont(forTextStyle: .subheadline),
                color: .adamant.chatPlaceholderTextColor 
            ).parse(.localized("Delegates.HeaderText"))
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.firstLineHeadIndent = 10
            paragraphStyle.headIndent = 10
       
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: .init(location: .zero, length: attributedString.length)
        )
        
        textView.attributedText = attributedString
        textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.adamant.active]
        
        textView.sizeToFit()
        
        return textView
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(AdamantDelegateCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = 50
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelectionDuringEditing = true
        tableView.refreshControl = refreshControl
        return tableView
    }()
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = true
        return controller
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    
    private lazy var bottomPanel = DelegatesBottomPanel()
    
    private(set) var delegates: [CheckedDelegate] = [CheckedDelegate]()
    private var filteredDelegates: [Int]?
    private var timerSubscription: AnyCancellable?
    private var loadingView: LoadingView?
    private var originalInsets: UIEdgeInsets?
    private var didShow: Bool = false
    
    // Can start with 'u' or 'U', then 1-20 digits
    private let possibleAddressRegEx = try! NSRegularExpression(pattern: "^[uU]{0,1}\\d{1,20}$", options: [])
    
    // MARK: - Lifecycle
    
    init(
        apiService: AdamantApiServiceProtocol,
        accountService: AccountService,
        dialogService: DialogService,
        screensFactory: ScreensFactory
    ) {
        self.apiService = apiService
        self.accountService = accountService
        self.dialogService = dialogService
        self.screensFactory = screensFactory
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        setupViews()
        setColors()
        setupLoadingView()
        handleRefresh(refreshControl)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        guard let address = accountService.account?.address else {
            refreshControl.endRefreshing()
            self.dialogService.showRichError(error: AccountServiceError.userNotLogged)
            return
        }
        
        Task {
            let result = await apiService.getDelegatesWithVotes(
                for: address,
                limit: activeDelegates
            )
            
            switch result {
            case .success(let delegates):
                let checkedNames = self.delegates
                    .filter { $0.isChecked }
                    .map { $0.delegate.username }
                
                let checkedDelegates = delegates.map { CheckedDelegate(delegate: $0) }
                for name in checkedNames {
                    if let i = delegates.firstIndex(where: { $0.username == name }) {
                        checkedDelegates[i].isChecked = true
                    }
                }
                
                self.delegates = checkedDelegates
                self.tableView.reloadData()
            case .failure(let error):
                self.dialogService.showRichError(error: error)
            }
            
            refreshControl.endRefreshing()
            self.updateVotePanel()
            self.removeLoadingView()
        }
    }
    
    @objc private func activateSearch() {
        if let bar = navigationItem.searchController?.searchBar, !bar.isFirstResponder {
            bar.becomeFirstResponder()
        }
    }
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
    }
    
    private func setupNavigationItem() {
        navigationItem.title = String.adamant.delegates.title
        navigationItem.searchController = searchController
        
        navigationItem.rightBarButtonItem = .init(
            barButtonSystemItem: .search,
            target: self,
            action: #selector(activateSearch)
        )
    }
    
    private func openURL(_ url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = UIColor.adamant.primary
        safari.modalPresentationStyle = .overFullScreen
        present(safari, animated: true, completion: nil)
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(bottomPanel)
        
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomPanel.snp.top)
        }
        
        bottomPanel.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
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
    
    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        return self.headerTextView
    }
    
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = screensFactory.makeDelegateDetails()
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
private extension DelegatesListViewController {
    func vote() {
        if timerSubscription != nil {
            self.dialogService.showWarning(withMessage: String.adamant.delegates.timeOutBeforeNewVote)
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
        
        guard account.balance > Decimal(votingCost) else {
            self.dialogService.showWarning(withMessage: String.adamant.delegates.notEnoughtTokensForVote)
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

        Task {
            let result = await apiService.voteForDelegates(
                from: account.address,
                keypair: keypair,
                votes: votes
            )
            
            dialogService.dismissProgress()
            
            switch result {
            case .success:
                dialogService.showSuccess(withMessage: String.adamant.delegates.success)

                checkedDelegates.forEach {
                    $1.isChecked = false
                    $1.delegate.voted = !$1.delegate.voted
                    $1.isUpdating = true
                }
                
                tableView.reloadData()
                updateVotePanel()
                scheduleUpdate()

            case .failure(let error):
                dialogService.showRichError(error: TransfersProviderError.serverError(error))
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
private extension DelegatesListViewController {
    func checkedDelegateFor(indexPath: IndexPath) -> CheckedDelegate {
        if let filtered = filteredDelegates {
            return delegates[filtered[indexPath.row]]
        } else {
            return delegates[indexPath.row]
        }
    }
    
    func scheduleUpdate() {
        timerSubscription = Timer.publish(every: 20, on: .main, in: .default)
            .autoconnect()
            .first()
            .sink { [weak self] _ in self?.updateTimerCallback() }
    }
    
    func updateTimerCallback() {
        handleRefresh(refreshControl)
        timerSubscription = nil
    }
    
    func updateVotePanel() {
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
        let newVotesColor = changes.count > maxVotes ? UIColor.adamant.attention : UIColor.adamant.primary
        let totalVotesColor = totalVoted > maxTotalVotes ? UIColor.adamant.attention : UIColor.adamant.primary
        
        DispatchQueue.onMainAsync { [self] in
            bottomPanel.model = .init(
                upvotes: upvoted,
                downvotes: downvoted,
                new: (changes.count, maxVotes),
                total: (totalVoted, maxTotalVotes),
                cost: "\(votingCost) \(AdmWalletService.currencySymbol)",
                isSendingEnabled: votingEnabled,
                newVotesColor: newVotesColor,
                totalVotesColor: totalVotesColor,
                sendAction: { [weak self] in self?.vote() }
            )
        }
    }
    
    func setupLoadingView() {
        let loadingView = LoadingView()
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        loadingView.startAnimating()
        
        self.loadingView = loadingView
    }
    
    func removeLoadingView() {
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

// MARK: - UITextViewDelegate
extension DelegatesListViewController: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        openURL(URL)
        return false
    }
}
