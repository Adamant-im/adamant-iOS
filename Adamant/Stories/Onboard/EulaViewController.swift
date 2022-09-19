//
//  EulaViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 10/11/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class EulaViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var eulaTextView: UITextView!
    @IBOutlet var buttons: [UIButton]!
    
    var onAccept: (()->Void)?
    var onDecline: (()->Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("EULA.Title", comment: "")

        setColors()
    }
    
    // MARK: - Other
    
    private func setColors() {
        buttons.forEach { btn in
            btn.setTitleColor(UIColor.adamant.textColor, for: .normal)
        }
        eulaTextView.textColor = UIColor.adamant.textColor
        view.backgroundColor = UIColor.adamant.welcomeBackgroundColor
    }
    
    // MARK: - Actions
    
    @IBAction func handleAccept() {
        DispatchQueue.main.async { [weak self] in
            self?.onAccept?()
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func handleDecline() {
        DispatchQueue.main.async { [weak self] in
            self?.onDecline?()
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
