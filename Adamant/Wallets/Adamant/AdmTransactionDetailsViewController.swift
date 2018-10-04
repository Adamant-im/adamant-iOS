//
//  AdmTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class AdmTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    
    // MARK: - Dependencies
    var accountService: AccountService!
    var transfersProvider: TransfersProvider!
    var router: Router!
    
    // MARK: - Properties
    private let autoupdateInterval: TimeInterval = 5.0
    
    weak var timer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startUpdate()
    }
    
    deinit {
        stopUpdate()
    }
    
//    override func goToChat() {
//        guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
//            dialogService.showError(withMessage: "TransactionDetailsViewController: Failed to get ChatViewController", error: nil)
//            return
//        }
//
//        guard let chatroom = transaction?.chatroom else {
//            dialogService.showError(withMessage: "TransactionDetailsViewController: Failed to get chatroom for transaction.", error: nil)
//            return
//        }
//
//        guard let account = self.accountService.account else {
//            dialogService.showError(withMessage: "TransactionDetailsViewController: User not logged.", error: nil)
//            return
//        }
//
//        vc.account = account
//        vc.chatroom = chatroom
//        vc.hidesBottomBarWhenPushed = true
//
//        if let nav = self.navigationController {
//            nav.pushViewController(vc, animated: true)
//        } else {
//            self.present(vc, animated: true)
//        }
//    }
    
    // MARK: - Autoupdate
    
    func startUpdate() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: autoupdateInterval, repeats: true) { [weak self] _ in
            guard let id = self?.transaction?.id else {
                return
            }
            
            self?.transfersProvider.refreshTransfer(id: id) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    
                case .failure:
                    return
                }
            }
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
    }
}
