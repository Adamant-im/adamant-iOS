//
//  AccountHeaderView.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

@MainActor
protocol AccountHeaderViewDelegate: AnyObject {
    func addressLabelTapped(from: UIView)
    func walletsButtonTapped(from: UIView)
}

final class AccountHeaderView: UIView {
    
    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var walletViewContainer: UIView!
    @IBOutlet weak var walletsButton: UIButton!
    
    weak var delegate: AccountHeaderViewDelegate?
    
    @IBAction func addressButtonTapped(_ sender: UIButton) {
        delegate?.addressLabelTapped(from: sender)
    }
    
    @IBAction func walletsButtonTapped(_ sender: UIButton) {
        delegate?.walletsButtonTapped(from: sender)
    }
}
