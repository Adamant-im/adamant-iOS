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
    
    private var circularBackgroundView: UIView?
    
    weak var delegate: AccountHeaderViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setWalletIcon(.regular, badgeCount: 0)
        addPersistentOutline()
        
        setupGestureRecognizers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let bgView = circularBackgroundView else { return }
        
        let iconFrame = secretWalletsImageView.frame
        let bgWidth = iconFrame.width * 2
        let bgHeight = iconFrame.height * 2
        bgView.frame = CGRect(x: iconFrame.midX - bgWidth / 2,
                              y: iconFrame.midY - bgHeight / 2,
                              width: bgWidth,
                              height: bgHeight)
        bgView.layer.cornerRadius = bgWidth / 2
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
}

private extension AccountHeaderView {
    func setupGestureRecognizers() {
        secretWalletsImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(walletsButtonTapped))
        secretWalletsImageView.addGestureRecognizer(tapGesture)
        
        guard self.circularBackgroundView != nil else { return }
        circularBackgroundView!.isUserInteractionEnabled = true
        let bgTapGesture = UITapGestureRecognizer(target: self, action: #selector(walletsButtonTapped))
        circularBackgroundView!.addGestureRecognizer(bgTapGesture)
    }
    
    func updateWalletBadge(count: Int) {
        guard let bgView = circularBackgroundView else { return }
        
        bgView.viewWithTag(99)?.removeFromSuperview()
        
        guard count > 0 else { return }
        
        let badgeLabel = UILabel()
        badgeLabel.tag = 99
        badgeLabel.text = "\(count)"
        badgeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        badgeLabel.textAlignment = .center
        badgeLabel.textColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .light ? .white : .black
        }
        badgeLabel.backgroundColor = .adamant.secondary
        
        let badgeSize: CGFloat = 24
        badgeLabel.layer.cornerRadius = badgeSize / 2
        badgeLabel.layer.masksToBounds = true
        
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        bgView.addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            badgeLabel.widthAnchor.constraint(equalToConstant: badgeSize),
            badgeLabel.heightAnchor.constraint(equalToConstant: badgeSize),
            badgeLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: 0),
            badgeLabel.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: 0)
        ])
    }

    private func addPersistentOutline() {
        let bgView = UIView()
        bgView.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .light
            ? .adamant.secondBackgroundColor
            : .adamant.background
        }
        
        secretWalletsImageView.superview?.insertSubview(bgView, belowSubview: secretWalletsImageView)
        self.circularBackgroundView = bgView
    }
    
    private func animateOutline() {
        guard let bgView = circularBackgroundView else { return }
        
        let originalColor = bgView.backgroundColor
        let highlightColor = UIColor.systemGray5
        
        UIView.animate(withDuration: 0.1, animations: {
            bgView.backgroundColor = highlightColor
            bgView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.secretWalletsImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                bgView.backgroundColor = originalColor
                bgView.transform = .identity
                self.secretWalletsImageView.transform = .identity
            })
        })
    }
}

extension AccountHeaderView {
    enum WalletIcon: String {
        case regular = "secret_wallets_regular"
        case secret = "secret_wallets_active"
        
        func image() -> UIImage? {
            return UIImage(named: self.rawValue)
        }
    }
}
