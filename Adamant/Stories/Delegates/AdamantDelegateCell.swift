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
    
    @IBOutlet weak var checkmarkBackgroundView: UIView!
    @IBOutlet weak var checkmarkImageView: UIImageView!

    @IBOutlet weak var checkboxExpander: UIView!
    
    // MARK: Properties
    
    weak var delegate: AdamantDelegateCellDelegate?
    
    private var _isChecked: Bool = false
    
    var isChecked: Bool {
        get {
            return _isChecked
        }
        set {
            setIsChecked(newValue, animated: false)
        }
    }
    
    func setIsChecked(_ checked: Bool, animated: Bool) {
        _isChecked = checked
        let view = checkmarkImageView!
        
        if animated {
            if checked {
                view.isHidden = false
                UIView.animate(withDuration: 0.15, animations: {
                    view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.1) {
                        view.transform = CGAffineTransform.identity
                    }
                })
            } else {
                UIView.animate(withDuration: 0.15, animations: {
                    view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                }, completion: { _ in
                    view.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
                    view.isHidden = true
                })
            }
        } else {
            view.isHidden = !checked
            view.transform = checked ? CGAffineTransform.identity : CGAffineTransform(scaleX: 0.0, y: 0.0)
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
            checkmarkImageView.image = isUpvoted ? #imageLiteral(resourceName: "Downvote") : #imageLiteral(resourceName: "Upvote")
        }
    }
    
    var checkmarkColor: UIColor {
        get {
            return checkmarkImageView.tintColor
        }
        set {
            checkmarkImageView.tintColor = newValue
        }
    }
    
    var checkmarkBorderColor: UIColor? {
        get {
            if let color = checkmarkBackgroundView.layer.borderColor {
                return UIColor(cgColor: color)
            } else {
                return nil
            }
        }
        set {
            checkmarkBackgroundView.layer.borderColor = newValue?.cgColor
        }
    }
    
    // MARK: Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        checkboxExpander.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onExpanderTap)))
        checkmarkBackgroundView.layer.borderWidth = 1
        checkmarkBackgroundView.layer.cornerRadius = checkmarkBackgroundView.frame.height / 2
    }
    
    @objc func onExpanderTap() {
        let state = !isChecked
        setIsChecked(state, animated: true)
        delegate?.delegateCell(self, didChangeCheckedStateTo: state)
    }
}
