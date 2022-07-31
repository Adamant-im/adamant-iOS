//
//  AdamantDelegateCell.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit


// MARK: Cell's Delegate
protocol AdamantDelegateCellDelegate: AnyObject {
    func delegateCell(_ cell: AdamantDelegateCell, didChangeCheckedStateTo state: Bool)
}

// MARK: -
class AdamantDelegateCell: UITableViewCell {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var votedLabel: UILabel!
    @IBOutlet weak var checkmarkView: CheckmarkView!
    
    // MARK: Properties
    
    weak var delegate: AdamantDelegateCellDelegate? {
        didSet {
            checkmarkView.onCheckmarkTap = { [weak self] in
                guard let self = self else { return }
                let newState = !self.checkmarkView.isChecked
                self.checkmarkView.setIsChecked(newState, animated: true)
                self.delegate?.delegateCell(self, didChangeCheckedStateTo: newState)
            }
        }
    }
    
    var isChecked: Bool {
        get {
            return checkmarkView.isChecked
        }
        set {
            checkmarkView.setIsChecked(newValue, animated: false)
        }
    }
    
    var delegateIsActive: Bool = false {
        didSet {
            statusLabel.text = delegateIsActive ? "●" : "○"
        }
    }
    
    var isUpvoted: Bool = false {
        didSet {
            votedLabel.text = isUpvoted ? "⬆︎" : ""
            checkmarkView.image = isUpvoted ? #imageLiteral(resourceName: "Downvote") : #imageLiteral(resourceName: "Upvote")
        }
    }
    
    var checkmarkColor: UIColor {
        get {
            checkmarkView.imageColor
        }
        set {
            checkmarkView.imageColor = newValue
        }
    }
    
    var checkmarkBorderColor: UIColor? {
        get {
            checkmarkView.borderColor
        }
        set {
            checkmarkView.borderColor = newValue
        }
    }
}
