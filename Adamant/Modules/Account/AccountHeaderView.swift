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
    @IBOutlet weak var secretWalletsImageView: UIImageView!
    private var outlineLayer: CAShapeLayer?
    
    weak var delegate: AccountHeaderViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setWalletIcon(.regular, badgeCount: 0)
        addPersistentOutline()
        
        setupGestureRecognizers()
    }
    
    func setWalletIcon(_ icon: WalletIcon, badgeCount: Int) {
        secretWalletsImageView.tintColor = .adamant.secondary
        secretWalletsImageView.image = .asset(named: icon.rawValue)?.withRenderingMode(.alwaysTemplate) ?? .init()
        updateWalletBadge(count: badgeCount)
    }
    
    @IBAction func addressButtonTapped(_ sender: UIButton) {
        delegate?.addressLabelTapped(from: sender)
    }
    
    @objc private func walletsButtonTapped() {
        animateOutline()
        delegate?.walletsButtonTapped(from: secretWalletsImageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let outlineLayer = outlineLayer else { return }
        guard !secretWalletsImageView.frame.isEmpty else { return }
        
        let imageView = secretWalletsImageView!
        let center = imageView.center
        let radius = imageView.bounds.width
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        outlineLayer.path = path.cgPath
    }
}

private extension AccountHeaderView {
    func setupGestureRecognizers() {
        secretWalletsImageView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(walletsButtonTapped))
        secretWalletsImageView.addGestureRecognizer(tapGesture)
    }
    
    func updateWalletBadge(count: Int) {
        secretWalletsImageView.viewWithTag(99)?.removeFromSuperview()
        
        guard count > 0 else { return }
        
    }
    
    private func addPersistentOutline() {
        
    }
    
    private func animateOutline() {
        
    }
}

extension AccountHeaderView{
    enum WalletIcon: String{
        case regular = "secret_wallets_regular"
        case secret = "secret_wallets_active"
        
        func image() -> UIImage? {
            return UIImage(named: self.rawValue)
        }
    }
}
