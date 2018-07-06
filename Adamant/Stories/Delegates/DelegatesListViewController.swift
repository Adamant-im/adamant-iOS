//
//  DelegatesListViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib.init(nibName: "DelegateCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.addSubview(self.refreshControl)
        
        self.refreshControl.beginRefreshing()
        handleRefresh(self.refreshControl)
    }

    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        apiService.getDelegates(limit: activeDelegates, offset: 0) { (result) in
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let delegate = delegates[indexPath.row]
        
        // TODO: Show delegate details
//        guard let controller = router.get(scene: AdamantScene.Delegates.delegatesDetails) as? DelegatesDetailsViewController else {
//            return
//        }
//
//        controller.delegate = delegate
//        navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? DelegateCell else {
                return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let delegate = delegates[indexPath.row]
        
        cell.nameLabel.text = delegate.username
        cell.rankLabel.text = "#\(delegate.rank)"
        cell.upTimeLabel.text = "\(delegate.productivity)%"
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}
