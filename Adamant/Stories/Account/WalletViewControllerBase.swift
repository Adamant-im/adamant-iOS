//
//  WalletViewControllerBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class WalletViewControllerBase: UIViewController, WalletViewController {
	
	// MARK: - WalletViewController
	
	var viewController: UIViewController { return self }
	var height: CGFloat { fatalError("height not implemented") }
	
	
	// MARK: - IBOutlets
	
	@IBOutlet weak var walletTitleLabel: UILabel!
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
    }
}
