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
    @IBOutlet weak var macOsImage: UIImageView!
    
    override func awakeFromNib() {
        badgeView.layer.cornerRadius = badgeView.bounds.height / 2
        clockView.contentMode = .scaleAspectFit
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
    
    var messageStatus: MessageStatus = .delivered {
        didSet {
            let isPhone = UIDevice.current.userInterfaceIdiom == .phone
            
            switch messageStatus {
            case .pending:
                if isPhone {
                    clockView.isHidden = false
                    clockView.image = .asset(named: "status_pending")
                    clockView.tintColor = .adamant.secondary
                    macOsImage.isHidden = true
                    lastMessageLeadingAnchor.constant = 27
                } else {
                    macOsImage.isHidden = false
                    macOsImage.image = .asset(named: "status_pending")
                    macOsImage.tintColor = .adamant.secondary
                    clockView.isHidden = true
                }
                
            case .failed:
                if isPhone {
                    clockView.isHidden = false
                    clockView.image = .asset(named: "status_failed")
                    clockView.tintColor = .adamant.attention
                    macOsImage.isHidden = true
                    lastMessageLeadingAnchor.constant = 27
                } else {
                    macOsImage.isHidden = false
                    macOsImage.image = .asset(named: "status_failed")
                    macOsImage.tintColor = .adamant.attention
                    clockView.isHidden = true
                }
                
            case .delivered:
                clockView.isHidden = true
                macOsImage.isHidden = true
                lastMessageLeadingAnchor.constant = 10
            }
        }
    }
}
