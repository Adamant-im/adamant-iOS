//
//  EulaViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 10/11/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class EulaViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func handleAccept() {
        DispatchQueue.main.async { [weak self] in
            UserDefaults.standard.set(true, forKey: StoreKey.application.eulaScreensIsShown)
            self?.dismiss(animated: true, completion: nil)
        }
    }

}
