//
//  AccountDependencies.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject

extension Container {
	func registerAdamantAccountStory() {
		self.storyboardInitCompleted(AccountViewController.self) { r, c in
			c.accountService = r.resolve(AccountService.self)
			c.dialogService = r.resolve(DialogService.self)
		}
		self.storyboardInitCompleted(TransactionsViewController.self) { (r, c) in
			c.apiService = r.resolve(ApiService.self)
			c.cellFactory = r.resolve(CellFactory.self)
		}
		self.storyboardInitCompleted(TransferViewController.self) { (r, c) in
			c.apiService = r.resolve(ApiService.self)
			c.accountService = r.resolve(AccountService.self)
			c.dialogService = r.resolve(DialogService.self)
		}
		self.storyboardInitCompleted(TransactionDetailsViewController.self) { (r, c) in
			c.dialogService = r.resolve(DialogService.self)
			c.exportTools = r.resolve(ExportTools.self)
		}
	}
}
