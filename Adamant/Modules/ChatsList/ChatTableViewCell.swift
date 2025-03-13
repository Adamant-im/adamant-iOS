//
//  ChatTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import FreakingSimpleRoundImageView
import CommonKit

final class ChatTableViewCell: UITableViewCell {
    
    static var defaultAvatar: UIImage = .asset(named: "avatar-chat-placeholder") ?? .init()
    static let shortDescriptionTextSize: CGFloat = 15.0
    
    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: RoundImageView!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var badgeView: UIView!
    @IBOutlet weak var clockView: UIImageView!
    @IBOutlet weak var lastMessageLeadingAnchor: NSLayoutConstraint!
    
    override func awakeFromNib() {
        Task { @MainActor in
            badgeView.layer.cornerRadius = badgeView.bounds.height / 2
            clockView.contentMode = .scaleAspectFit
            clockView.image = UIImage.asset(named: "status_pending")
            clockView.tintColor = .adamant.secondary
        }
    }
    var avatarImage: UIImage? {
        get {
            return avatarImageView.image
        }
        set {
            if let avatarImage = newValue {
                avatarImageView.image = avatarImage
            } else {
                avatarImageView.image = ChatTableViewCell.defaultAvatar
            }
        }
    }
    
    var borderWidth: CGFloat {
        get {
            return avatarImageView.borderWidth
        }
        set {
            avatarImageView.borderWidth = newValue
        }
    }
    
    var borderColor: UIColor? {
        get {
            return avatarImageView.borderColor
        }
        set {
            avatarImageView.borderColor = newValue
        }
    }
    
    var hasUnreadMessages: Bool = false {
        didSet {
            badgeView.isHidden = !hasUnreadMessages
        }
    }
    
    var badgeColor: UIColor? {
        get {
            return badgeView.backgroundColor
        }
        set {
            badgeView.backgroundColor = newValue
        }
    }
    var isClockVisible: Bool {
        get {
            return !clockView.isHidden
        }
        set {
            if newValue {
                clockView.isHidden = false
                lastMessageLeadingAnchor.constant = 27
            } else {
                self.clockView.isHidden = true
                self.lastMessageLeadingAnchor.constant = 10
                self.layoutIfNeeded()
            }
        }
    }
}
