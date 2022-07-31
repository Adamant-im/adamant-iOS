//
//  EulaViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 10/11/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class EulaViewController: UIViewController {
    
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("EULA.Title", comment: "")

        view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "stripeBg"))
    }
    
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
